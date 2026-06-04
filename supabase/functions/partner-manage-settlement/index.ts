// partner-manage-settlement — Manage partner settlement bank account
// Issue #312: RLS write strategy 전환
// Fix #2185 (Batch 6): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)

import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";

const FN = "partner-manage-settlement";

type BankOption = {
  readonly code: string;
  readonly name: string;
};

const BANK_CATALOG: readonly BankOption[] = [
  { code: "kb", name: "KB국민은행" },
  { code: "shinhan", name: "신한은행" },
  { code: "hana", name: "하나은행" },
  { code: "woori", name: "우리은행" },
  { code: "ibk", name: "IBK기업은행" },
  { code: "nh", name: "NH농협은행" },
  { code: "kakao", name: "카카오뱅크" },
  { code: "toss", name: "토스뱅크" },
  { code: "kbank", name: "케이뱅크" },
] as const;

const BANK_BY_CODE = new Map<string, BankOption>(
  BANK_CATALOG.map((bank) => [bank.code, bank]),
);
const BANK_BY_NAME = new Map<string, BankOption>(
  BANK_CATALOG.map((bank) => [bank.name, bank]),
);

// Issue #3047: BankAccountPage spec keeps the 10-16 digit client contract.
const ACCOUNT_NUMBER_RE = /^[0-9]{10,16}$/;

function resolveBank(body: Record<string, unknown>) {
  const bankCode = typeof body.bank_code === "string"
    ? body.bank_code.trim()
    : "";
  if (bankCode) return BANK_BY_CODE.get(bankCode);

  // Backward-compatible fallback for clients still sending only bank_name.
  const bankName = typeof body.bank_name === "string"
    ? body.bank_name.trim()
    : "";
  return BANK_BY_NAME.get(bankName);
}

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  if (ctx.auth.type !== "user") {
    return errorResponse("Unexpected auth type", 500);
  }
  const userId = ctx.auth.userId;

  try {
    // Parse body
    const result = await parseAction(req);
    if (result instanceof Response) return result;
    const { action, body } = result;
    if (!action) return errorResponse("Missing action", 400);

    // ─── upsert_bank_account ───
    if (action === "upsert_bank_account") {
      const partnerId = typeof body.partner_id === "string"
        ? body.partner_id.trim()
        : "";
      if (!partnerId) {
        return errorResponse("Missing partner_id", 400);
      }

      const bank = resolveBank(body);
      if (!bank) {
        return errorResponse("Missing or unsupported bank_code", 400);
      }

      const accountHolder = typeof body.account_holder === "string"
        ? body.account_holder.trim()
        : "";
      if (!accountHolder) {
        return errorResponse("Missing account_holder", 400);
      }

      const rawAccountNumber = typeof body.account_number === "string"
        ? body.account_number.trim()
        : "";
      if (!rawAccountNumber) {
        return errorResponse("Missing account_number", 400);
      }

      // Fix #312 / Issue #3047: strip separators, then enforce 10-16 digits.
      const accountNumber = rawAccountNumber.replace(/[-\s]/g, "");
      if (!ACCOUNT_NUMBER_RE.test(accountNumber)) {
        return errorResponse("Invalid account_number format", 400);
      }

      // Check partner permission
      const permCheck = await requirePartnerPermission(
        supabase,
        partnerId,
        userId,
        ["SETTLEMENT_EDIT"],
      );
      if (permCheck) return permCheck;

      // Build upsert record — only allow whitelisted fields, use validated values
      const record: Record<string, unknown> = {
        partner_id: partnerId,
        bank_code: bank.code,
        bank_name: bank.name,
        account_holder: accountHolder,
        account_number: accountNumber,
        bank_verification_status: "manual_review_pending",
        bank_verification_reason: "partner_submitted_bank_account",
        bank_verification_requested_at: new Date().toISOString(),
        bank_verified_at: null,
      };

      const { error: upsertError } = await supabase
        .from("partner_settlements")
        .upsert(record, { onConflict: "partner_id" });

      if (upsertError) {
        return errorResponse(
          `Failed to upsert bank account: ${upsertError.message}`,
          500,
        );
      }

      return successResponse({
        success: true,
        bank_verification_status: "manual_review_pending",
      });
    }

    // ─── request_manual_bank_account_review ───
    if (action === "request_manual_bank_account_review") {
      const partnerId = typeof body.partner_id === "string"
        ? body.partner_id.trim()
        : "";
      if (!partnerId) {
        return errorResponse("Missing partner_id", 400);
      }

      const permCheck = await requirePartnerPermission(
        supabase,
        partnerId,
        userId,
        ["SETTLEMENT_EDIT"],
      );
      if (permCheck) return permCheck;

      const { error: updateError } = await supabase
        .from("partner_settlements")
        .update({
          bank_verification_status: "manual_review_pending",
          bank_verification_reason: "partner_requested_manual_review",
          bank_verification_requested_at: new Date().toISOString(),
          bank_verified_at: null,
        })
        .eq("partner_id", partnerId);

      if (updateError) {
        return errorResponse(
          `Failed to request manual bank account review: ${updateError.message}`,
          500,
        );
      }

      return successResponse({
        success: true,
        bank_verification_status: "manual_review_pending",
      });
    }

    return errorResponse(`Unknown action: ${action}`, 400);
  } catch (error) {
    log({
      function: FN,
      level: "error",
      message: "partner-manage-settlement failed",
      metadata: {
        detail: error instanceof Error ? error.message : String(error),
      },
    });
    return errorResponse("Internal server error", 500);
  }
};

minglitEdgeFunction(handler);
