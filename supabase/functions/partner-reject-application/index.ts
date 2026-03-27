// partner-reject-application — Reject event applications with reason
// Issue #517: 파트너 대시보드 리디자인 — 신청 거절 API

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
    return await handleRequest(req);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(message, 500);
  }
});

async function handleRequest(req: Request): Promise<Response> {
  // 1. Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // 2. Parse body
  let body: Record<string, unknown>;
  try {
    const parsed = await req.json();
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return errorResponse("Request body must be a JSON object", 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const supabase = createServiceClient();

  const applicationId = body.application_id;
  if (typeof applicationId !== "string" || !applicationId) {
    return errorResponse("Missing application_id", 400);
  }

  const reason = body.reason;
  if (typeof reason !== "string" || !reason.trim()) {
    return errorResponse("Missing or empty rejection reason", 400);
  }

  // Fetch application with event → party → partner chain
  const { data: app, error: fetchError } = await supabase
    .from("event_applications")
    .select("id, status, event_id, events!inner(party_id, parties!inner(partner_id))")
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

  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

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
}

// ── Permission check ──
async function checkPartnerPermission(
  supabase: SupabaseClient,
  partnerId: string,
  userId: string,
): Promise<void | Response> {
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("permissions, role")
    .eq("partner_id", partnerId)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  // Owner bypass — defense-in-depth even if DB trigger grants all permissions
  if (perm?.role === "owner") return;

  const permissions = (perm?.permissions as string[] | null) ?? [];
  const hasPermission =
    permissions.includes("EVENT_MANAGE") ||
    permissions.includes("APPLICATION_MANAGE");
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
