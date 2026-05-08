// partner-reject-application — Reject event applications with reason
// Issue #517: 파트너 대시보드 리디자인 — 신청 거절 API

import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  // wrapper guarantees type === "user" per auth-manifest callers: ["user"]
  const userId = (ctx.auth as { type: "user"; userId: string }).userId;

  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const applicationId = body.application_id;
  if (typeof applicationId !== "string" || !applicationId) {
    return errorResponse("Missing application_id", 400);
  }
  if (!UUID_RE.test(applicationId)) {
    return errorResponse("Invalid application_id", 400);
  }

  const reason = body.reason;
  if (typeof reason !== "string" || !reason.trim()) {
    return errorResponse("Missing or empty rejection reason", 400);
  }

  // Fetch application with event → party → partner chain
  const { data: app, error: fetchError } = await supabase
    .from("event_applications")
    .select(
      "id, status, event_id, events!inner(party_id, parties!inner(partner_id))",
    )
    .eq("id", applicationId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load application", 500);
  if (!app) return errorResponse("Application not found", 404);

  // Verify status is rejectable
  if (app.status !== "pending" && app.status !== "pending_review") {
    return errorResponse(
      `Cannot reject application with status '${app.status}'`,
      400,
    );
  }

  // Check partner permission
  const event = app.events as Record<string, unknown>;
  const party = event.parties as Record<string, unknown>;
  const partnerId = party.partner_id as string;

  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["EVENT_MANAGE", "APPLICATION_MANAGE"]);
  if (permCheck) return permCheck;

  // Compare-and-set: only update if status is still pending/pending_review
  const { data: updated, error: updateError } = await supabase
    .from("event_applications")
    .update({
      status: "rejected",
      rejection_reason: reason.trim(),
      updated_at: new Date().toISOString(),
    })
    .eq("id", applicationId)
    .in("status", ["pending", "pending_review"])
    .select("id");

  if (updateError) return errorResponse("Failed to reject application", 500);
  if (!updated || updated.length === 0) {
    return errorResponse("Application already processed", 409);
  }

  return successResponse({
    rejected: 1,
    application_id: applicationId,
  });
};

minglitEdgeFunction(handler);
