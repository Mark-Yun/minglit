// Fix #1783: partner permission 검증 공통 함수
// — 10 EF에 분산된 checkPartnerPermission 패턴 통합
// — ownerBypass: true (default) — role='owner'이면 permissions 배열 무관하게 pass
import { type SupabaseClient } from "@supabase/supabase-js";

import { errorResponse } from "./response_utils.ts";

export type PartnerPermission =
  | "PARTNER_EDIT"
  | "SETTLEMENT_VIEW"
  | "SETTLEMENT_EDIT"
  | "MEMBER_MANAGE"
  | "PARTY_MANAGE"
  | "VERIFY_LIST_VIEW"
  | "USER_DATA_VIEW"
  | "VERIFY_REVIEW"
  | "COMMENT_MANAGE"
  | "EVENT_MANAGE"
  | "APPLICATION_MANAGE";

export async function requirePartnerPermission(
  supabase: SupabaseClient,
  partnerId: string,
  userId: string,
  required: PartnerPermission[],
  opts: { ownerBypass?: boolean } = { ownerBypass: true },
): Promise<Response | null> {
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("role, permissions")
    .eq("partner_id", partnerId)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  if (opts.ownerBypass !== false && perm?.role === "owner") return null;

  const permissions = (perm?.permissions as string[] | null) ?? [];
  const hasPermission = required.some((r) => permissions.includes(r));
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }

  return null;
}
