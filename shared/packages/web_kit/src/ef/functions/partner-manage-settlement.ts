// partner-manage-settlement — 파트너 정산 계좌 관리 (action dispatch)
// manifest: caller=user (파트너 권한은 서버에서 requirePartnerPermission(SETTLEMENT_EDIT) 으로 검사)
// 역산 출처: supabase/functions/partner-manage-settlement/index.ts
//           + migrations/20260604163000_partner_bank_account_verification_status.sql
//           + migrations/20260509000001_fix_partner_settlements_insert_rls.sql
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export type PartnerManageSettlementAction =
  | "upsert_bank_account"
  | "request_manual_bank_account_review";

/** 정산 계좌 등록/변경 — bank_code 우선, 미지정 시 bank_name 으로 폴백. */
export interface PartnerUpsertBankAccountRequest {
  action: "upsert_bank_account";
  partner_id: string;
  /** BANK_CATALOG code (kb/shinhan/hana/...) — 권장 경로 */
  bank_code?: string;
  /** 구버전 폴백: code 없이 은행명만 보낼 때 (서버가 BANK_BY_NAME 매칭) */
  bank_name?: string;
  account_holder: string;
  /** 서버가 구분자(-, 공백) 제거 후 10~16자리 숫자로 검증 */
  account_number: string;
}

/** 기존 계좌에 대한 수동 심사 재요청 (계좌 정보 변경 없음). */
export interface PartnerRequestManualBankAccountReviewRequest {
  action: "request_manual_bank_account_review";
  partner_id: string;
}

export type PartnerManageSettlementRequest =
  | PartnerUpsertBankAccountRequest
  | PartnerRequestManualBankAccountReviewRequest;

export const partnerManageSettlementResponseSchema = z.object({
  success: z.literal(true),
  /** 두 action 모두 제출 직후 "manual_review_pending" 로 천이 */
  bank_verification_status: z.string(),
});
export type PartnerManageSettlementResponse = z.infer<
  typeof partnerManageSettlementResponseSchema
>;

export function partnerManageSettlement(
  supabase: SessionSource,
  body: PartnerManageSettlementRequest,
  options?: { signal?: AbortSignal },
): Promise<PartnerManageSettlementResponse> {
  return callEdgeFunction(supabase, "partner-manage-settlement", body, {
    schema: partnerManageSettlementResponseSchema,
    signal: options?.signal,
  });
}
