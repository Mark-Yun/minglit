// partner-manage-member — Manage partner member roles and permissions
// Issue #313: RLS write strategy 전환
// Fix #2185 (Batch 6): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)

import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";

const FN = "partner-manage-member";

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

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  if (ctx.auth.type !== "user") return errorResponse("Unexpected auth type", 500);
  const userId = ctx.auth.userId;

  try {
    // Parse body
    const result = await parseAction(req);
    if (result instanceof Response) return result;
    const { action, body } = result;
    if (!action) return errorResponse("Missing action", 400);

    // ─── update_role ───
    if (action === "update_role") {
      const partnerId = typeof body.partner_id === "string"
        ? body.partner_id.trim()
        : "";
      if (!partnerId) return errorResponse("Missing partner_id", 400);

      const targetUserId = typeof body.user_id === "string"
        ? body.user_id.trim()
        : "";
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
      const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["MEMBER_MANAGE"]);
      if (permCheck) return permCheck;

      const { error: updateError } = await supabase
        .from("partner_member_permissions")
        .update({ role })
        .eq("partner_id", partnerId)
        .eq("user_id", targetUserId);

      if (updateError) {
        return errorResponse(
          `Failed to update role: ${updateError.message}`,
          500,
        );
      }

      return successResponse({ success: true });
    }

    // ─── update_permissions ───
    if (action === "update_permissions") {
      const partnerId = typeof body.partner_id === "string"
        ? body.partner_id.trim()
        : "";
      if (!partnerId) return errorResponse("Missing partner_id", 400);

      const targetUserId = typeof body.user_id === "string"
        ? body.user_id.trim()
        : "";
      if (!targetUserId) return errorResponse("Missing user_id", 400);

      if (!Array.isArray(body.permissions)) {
        return errorResponse("Missing permissions", 400);
      }

      const permissions = body.permissions as unknown[];

      // Fix #313: permissions 화이트리스트 검증
      for (const perm of permissions) {
        if (
          typeof perm !== "string" ||
          !VALID_PERMISSIONS.includes(perm as typeof VALID_PERMISSIONS[number])
        ) {
          return errorResponse(`Invalid permission: ${perm}`, 400);
        }
      }

      // Check MEMBER_MANAGE permission
      const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["MEMBER_MANAGE"]);
      if (permCheck) return permCheck;

      const { error: updateError } = await supabase
        .from("partner_member_permissions")
        .update({ permissions })
        .eq("partner_id", partnerId)
        .eq("user_id", targetUserId);

      if (updateError) {
        return errorResponse(
          `Failed to update permissions: ${updateError.message}`,
          500,
        );
      }

      return successResponse({ success: true });
    }

    return errorResponse(`Unknown action: ${action}`, 400);
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "partner-manage-member failed",
      metadata: { detail },
    });
    const env = Deno.env.get("ENVIRONMENT");
    const exposeDetail = env === "local" || env === "development";
    return errorResponse(
      exposeDetail ? `${FN}: ${detail}` : "Internal server error",
      500,
    );
  }
};

minglitEdgeFunction(handler);
