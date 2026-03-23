// partner-manage-member — Manage partner member roles and permissions
// Issue #313: RLS write strategy 전환

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

// Fix #313: role 화이트리스트 — partner_role enum과 일치
const VALID_ROLES = ["owner", "manager", "staff"] as const;

// Fix #313: permissions 화이트리스트 — sync_partner_member_permissions 트리거와 일치
const VALID_PERMISSIONS = [
  "PARTNER_EDIT",
  "SETTLEMENT_VIEW",
  "SETTLEMENT_EDIT",
  "MEMBER_MANAGE",
  "PARTY_MANAGE",
  "VERIFY_LIST_VIEW",
  "USER_DATA_VIEW",
  "VERIFY_REVIEW",
  "COMMENT_MANAGE",
] as const;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
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

    const action = body.action as string | undefined;
    if (typeof action !== "string" || !action) return errorResponse("Missing action", 400);

    // 3. Supabase client (service role)
    const supabase = createServiceClient();

    // ─── update_role ───
    if (action === "update_role") {
      const partnerId = typeof body.partner_id === "string" ? body.partner_id.trim() : "";
      if (!partnerId) return errorResponse("Missing partner_id", 400);

      const targetUserId = typeof body.user_id === "string" ? body.user_id.trim() : "";
      if (!targetUserId) return errorResponse("Missing user_id", 400);

      const role = typeof body.role === "string" ? body.role.trim() : "";
      if (!role) return errorResponse("Missing role", 400);

      // Fix #313: role 화이트리스트 검증
      if (!VALID_ROLES.includes(role as typeof VALID_ROLES[number])) {
        return errorResponse(`Invalid role: ${role}`, 400);
      }

      // Fix #313: 자기 자신 role 변경 방지
      if (targetUserId === userId) {
        return errorResponse("Cannot change own role", 400);
      }

      // Check MEMBER_MANAGE permission
      const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
      if (permCheck instanceof Response) return permCheck;

      const { error: updateError } = await supabase
        .from("partner_member_permissions")
        .update({ role })
        .eq("partner_id", partnerId)
        .eq("user_id", targetUserId);

      if (updateError) {
        return errorResponse(`Failed to update role: ${updateError.message}`, 500);
      }

      return successResponse({ success: true });
    }

    // ─── update_permissions ───
    if (action === "update_permissions") {
      const partnerId = typeof body.partner_id === "string" ? body.partner_id.trim() : "";
      if (!partnerId) return errorResponse("Missing partner_id", 400);

      const targetUserId = typeof body.user_id === "string" ? body.user_id.trim() : "";
      if (!targetUserId) return errorResponse("Missing user_id", 400);

      if (!Array.isArray(body.permissions)) {
        return errorResponse("Missing permissions", 400);
      }

      const permissions = body.permissions as unknown[];

      // Fix #313: permissions 화이트리스트 검증
      for (const perm of permissions) {
        if (typeof perm !== "string" || !VALID_PERMISSIONS.includes(perm as typeof VALID_PERMISSIONS[number])) {
          return errorResponse(`Invalid permission: ${perm}`, 400);
        }
      }

      // Check MEMBER_MANAGE permission
      const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
      if (permCheck instanceof Response) return permCheck;

      const { error: updateError } = await supabase
        .from("partner_member_permissions")
        .update({ permissions })
        .eq("partner_id", partnerId)
        .eq("user_id", targetUserId);

      if (updateError) {
        return errorResponse(`Failed to update permissions: ${updateError.message}`, 500);
      }

      return successResponse({ success: true });
    }

    return errorResponse(`Unknown action: ${action}`, 400);
  } catch (error) {
    console.error("partner-manage-member failed", error);
    return errorResponse("Internal server error", 500);
  }
});

// ─── Helper: check partner MEMBER_MANAGE permission ───
async function checkPartnerPermission(
  supabase: SupabaseClient,
  partnerId: string,
  userId: string,
): Promise<void | Response> {
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("role, permissions")
    .eq("partner_id", partnerId)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  // Fix #313: owner role 또는 MEMBER_MANAGE 권한 확인 (defense-in-depth)
  const hasPermission = perm?.role === "owner" ||
    ((perm?.permissions as string[] | null)?.includes("MEMBER_MANAGE") ?? false);
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
