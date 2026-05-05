// partner-review-applications — unified approve + reject in a single transaction
// Issue #2101: deferred batch commit UX — selected approve_ids + rejections with reasons

import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "partner-review-applications";

initSentry();

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

interface RejectionItem {
  application_id: string;
  reason: string;
}

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
      message: "partner-review-applications error",
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
  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing event_id", 400);
  }
  if (!UUID_RE.test(eventId)) {
    return errorResponse("Invalid event_id", 400);
  }

  const approvals: unknown = body.approvals ?? [];
  const rejections: unknown = body.rejections ?? [];

  if (!Array.isArray(approvals)) {
    return errorResponse("approvals must be an array", 400);
  }
  if (!Array.isArray(rejections)) {
    return errorResponse("rejections must be an array", 400);
  }
  if (approvals.length === 0 && rejections.length === 0) {
    return errorResponse("approvals and rejections cannot both be empty", 400);
  }

  // Validate approval IDs
  for (const id of approvals) {
    if (typeof id !== "string" || !UUID_RE.test(id)) {
      return errorResponse(`Invalid application_id in approvals: ${id}`, 400);
    }
  }

  // Validate rejections
  const validatedRejections: RejectionItem[] = [];
  for (const item of rejections) {
    if (!item || typeof item !== "object") {
      return errorResponse("Each rejection must be an object", 400);
    }
    const r = item as Record<string, unknown>;
    if (typeof r.application_id !== "string" || !UUID_RE.test(r.application_id)) {
      return errorResponse(`Invalid application_id in rejections: ${r.application_id}`, 400);
    }
    if (typeof r.reason !== "string" || !r.reason.trim()) {
      return errorResponse(`Missing or empty reason for application ${r.application_id}`, 400);
    }
    validatedRejections.push({
      application_id: r.application_id,
      reason: r.reason.trim(),
    });
  }

  const supabase = createServiceClient();

  // 3. Verify partner permission
  const { data: event, error: eventError } = await supabase
    .from("events")
    .select("id, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (eventError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  const party = event.parties as Record<string, unknown>;
  const partnerId = party.partner_id as string;

  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, [
    "EVENT_MANAGE",
    "APPLICATION_MANAGE",
  ]);
  if (permCheck) return permCheck;

  // 4. Call batch review RPC (single transaction with event lock)
  const rejectionRows = validatedRejections.map((r) => `(${r.application_id},${r.reason})`);

  const { data: result, error: rpcError } = await supabase.rpc(
    "batch_review_event_applications",
    {
      p_event_id: eventId,
      p_approvals: approvals as string[],
      p_rejections: validatedRejections.map((r) => ({
        application_id: r.application_id,
        reason: r.reason,
      })),
    },
  );

  if (rpcError) {
    log({
      function: FN,
      level: "error",
      message: "batch_review_event_applications RPC failed",
      metadata: { detail: rpcError.message, event_id: eventId },
    });
    return errorResponse("Failed to process applications", 500);
  }

  const row = Array.isArray(result) ? result[0] : result;
  if (!row) return errorResponse("RPC returned no result", 500);

  return successResponse({
    approved: row.approved ?? [],
    rejected: row.rejected ?? [],
    skipped_due_to_capacity: row.skipped_due_to_capacity ?? [],
    skipped_already_processed: row.skipped_already_processed ?? [],
    remaining_slots_after: row.remaining_slots_after ?? 0,
  });
}
