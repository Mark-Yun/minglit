// partner-approve-application — Approve event applications (single + bulk)
// Issue #517: 파트너 대시보드 리디자인 — 신청 승인 API

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "partner-approve-application";

initSentry();

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
// Fix #1219: keep approval status filtering aligned with the capacity guard paths.
const APPROVABLE_STATUSES = ["pending", "pending_review"] as const;

Deno.serve(withHandler(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
    return await handleRequest(req);
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: "partner-approve-application error",
      metadata: { detail },
    });
    const env = Deno.env.get("ENVIRONMENT");
    const exposeDetail = env === "local" || env === "development";
    return errorResponse(
      exposeDetail ? `${FN}: ${detail}` : "Internal server error",
      500,
    );
  }
}));

async function handleRequest(req: Request): Promise<Response> {
  // 1. Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // 2. Parse body
  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;
  if (!action) {
    return errorResponse("Missing action", 400);
  }

  const supabase = createServiceClient();

  // ─── approve (single) ───
  if (action === "approve") {
    return handleApprove(supabase, body, userId);
  }

  // ─── bulk_approve ───
  if (action === "bulk_approve") {
    return handleBulkApprove(supabase, body, userId);
  }

  return errorResponse(`Unknown action: ${action}`, 400);
}

// ── Single approve ──
async function handleApprove(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const applicationId = body.application_id;
  if (typeof applicationId !== "string" || !applicationId) {
    return errorResponse("Missing application_id", 400);
  }
  if (!UUID_RE.test(applicationId)) {
    return errorResponse("Invalid application_id", 400);
  }

  // Fix #1219: load event capacity with the application so single approval can reject full events.
  const { data: app, error: fetchError } = await supabase
    .from("event_applications")
    .select(
      "id, status, event_id, events!inner(party_id, parties!inner(partner_id))",
    )
    .eq("id", applicationId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load application", 500);
  if (!app) return errorResponse("Application not found", 404);

  // Check partner permission first to avoid leaking application state
  const event = app.events as Record<string, unknown>;
  const party = event.parties as Record<string, unknown>;
  const partnerId = party.partner_id as string;

  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["EVENT_MANAGE", "APPLICATION_MANAGE"]);
  if (permCheck) return permCheck;

  // Verify status is approvable (after permission check)
  if (
    !APPROVABLE_STATUSES.includes(
      app.status as typeof APPROVABLE_STATUSES[number],
    )
  ) {
    return errorResponse(
      `Cannot approve application with status '${app.status}'`,
      400,
    );
  }

  // Fix #1219: route single approval through the DB capacity guard so the status flip is serialized per event.
  const { data: approvalResult, error: approvalError } = await supabase
    .rpc("approve_event_application_with_capacity_guard", {
      p_application_id: applicationId,
    });

  if (approvalError) return errorResponse("Failed to approve application", 500);

  const result = Array.isArray(approvalResult)
    ? approvalResult[0]
    : approvalResult;
  const resultStatus = result?.result_status as string | undefined;

  if (resultStatus === "approved") {
    return successResponse({ approved: 1, application_id: applicationId });
  }

  if (resultStatus === "event_full") {
    return errorResponse("정원이 초과되었습니다.", 409, { code: "EVENT_FULL" });
  }

  if (resultStatus === "already_processed") {
    return errorResponse("Application already processed", 409);
  }

  if (resultStatus === "not_found") {
    return errorResponse("Application not found", 404);
  }

  return errorResponse("Event capacity data is invalid", 500, {
    code: "INVALID_EVENT_CAPACITY",
  });
}

// ── Bulk approve ──
async function handleBulkApprove(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing event_id", 400);
  }
  if (!UUID_RE.test(eventId)) {
    return errorResponse("Invalid event_id", 400);
  }

  // Fix #1219: load event capacity so bulk approval can cap approvals at remaining slots.
  const { data: event, error: eventError } = await supabase
    .from("events")
    .select("id, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (eventError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  const party = event.parties as Record<string, unknown>;
  const partnerId = party.partner_id as string;

  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["EVENT_MANAGE", "APPLICATION_MANAGE"]);
  if (permCheck) return permCheck;

  // Fix #1219: route bulk approval through the DB capacity guard so oldest rows are approved under one event lock.
  const { data: bulkApprovalResult, error: bulkApprovalError } = await supabase
    .rpc("bulk_approve_event_applications_with_capacity_guard", {
      p_event_id: eventId,
    });

  if (bulkApprovalError) return errorResponse("Failed to bulk approve", 500);

  const result = Array.isArray(bulkApprovalResult)
    ? bulkApprovalResult[0]
    : bulkApprovalResult;
  const resultStatus = result?.result_status as string | undefined;

  if (resultStatus === "invalid_capacity") {
    return errorResponse("Event capacity data is invalid", 500, {
      code: "INVALID_EVENT_CAPACITY",
    });
  }

  if (resultStatus === "not_found") {
    return errorResponse("Event not found", 404);
  }

  const approvedCount = typeof result?.approved_count === "number"
    ? result.approved_count
    : 0;
  const skippedDueToCapacity =
    typeof result?.skipped_due_to_capacity === "number"
      ? result.skipped_due_to_capacity
      : 0;
  const remainingSlotsBeforeApproval =
    typeof result?.remaining_slots_before_approval === "number"
      ? result.remaining_slots_before_approval
      : 0;

  return successResponse({
    approved: approvedCount,
    event_id: eventId,
    skipped_due_to_capacity: skippedDueToCapacity,
    remaining_slots_before_approval: remainingSlotsBeforeApproval,
  });
}
