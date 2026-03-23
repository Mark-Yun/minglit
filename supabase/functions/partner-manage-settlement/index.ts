// partner-manage-settlement — Manage partner settlement bank account
// Issue #312: RLS write strategy 전환

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

// Fields allowed in upsert_bank_account action
const UPSERT_FIELDS = [
  "bank_name",
  "account_holder",
  "account_number",
] as const;

// Fix #312: 계좌번호 형식 검증 — 하이픈/공백 제거 후 숫자 6~20자리
const ACCOUNT_NUMBER_RE = /^[0-9]{6,20}$/;

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

    // ─── upsert_bank_account ───
    if (action === "upsert_bank_account") {
      const partnerId = typeof body.partner_id === "string" ? body.partner_id.trim() : "";
      if (!partnerId) {
        return errorResponse("Missing partner_id", 400);
      }

      // Validate required fields with trim
      const bankName = typeof body.bank_name === "string" ? body.bank_name.trim() : "";
      if (!bankName) {
        return errorResponse("Missing bank_name", 400);
      }

      const accountHolder = typeof body.account_holder === "string" ? body.account_holder.trim() : "";
      if (!accountHolder) {
        return errorResponse("Missing account_holder", 400);
      }

      const rawAccountNumber = typeof body.account_number === "string" ? body.account_number.trim() : "";
      if (!rawAccountNumber) {
        return errorResponse("Missing account_number", 400);
      }

      // Fix #312: 계좌번호 포맷 검증 — 하이픈/공백 제거 후 숫자만 6~20자리
      const accountNumber = rawAccountNumber.replace(/[-\s]/g, "");
      if (!ACCOUNT_NUMBER_RE.test(accountNumber)) {
        return errorResponse("Invalid account_number format", 400);
      }

      // Check partner permission
      const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
      if (permCheck instanceof Response) return permCheck;

      // Build upsert record — only allow whitelisted fields, use validated values
      const record: Record<string, unknown> = {
        partner_id: partnerId,
        bank_name: bankName,
        account_holder: accountHolder,
        account_number: accountNumber,
      };

      const { error: upsertError } = await supabase
        .from("partner_settlements")
        .upsert(record, { onConflict: "partner_id" });

      if (upsertError) {
        return errorResponse(`Failed to upsert bank account: ${upsertError.message}`, 500);
      }

      return successResponse({ success: true });
    }

    return errorResponse(`Unknown action: ${action}`, 400);
  } catch (error) {
    console.error("partner-manage-settlement failed", error);
    return errorResponse("Internal server error", 500);
  }
});

// ─── Helper: check partner permission ───
async function checkPartnerPermission(
  supabase: SupabaseClient,
  partnerId: string,
  userId: string,
): Promise<void | Response> {
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("permissions")
    .eq("partner_id", partnerId)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  // Fix #312: SETTLEMENT_EDIT 권한 또는 owner 권한 확인
  const hasPermission = (perm?.permissions as string[] | null)?.includes("SETTLEMENT_EDIT") ?? false;
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
