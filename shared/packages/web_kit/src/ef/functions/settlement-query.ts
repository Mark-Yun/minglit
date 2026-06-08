// settlement-query — 파트너 정산/지급 내역 조회 (PortOne getPartnerSettlements / getPayouts)
// manifest: caller=user (파트너 권한은 서버에서 requirePartnerPermission(SETTLEMENT_VIEW) 으로 검사)
// 역산 출처: supabase/functions/settlement-query/index.ts
//           + migrations/20260314000001_settlement_phase1_schema.sql (partners.portone_partner_id)
//           + migrations/20260316000005_settlement_phase5_partner_access.sql
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export type SettlementQueryType = "settlements" | "payouts";

export interface SettlementQueryRequest {
  partner_id: string;
  /** "settlements" → getPartnerSettlements / "payouts" → getPayouts */
  type: SettlementQueryType;
  /**
   * 정산 내역 조회 기간 (type="settlements" 에서만 PortOne dateRange 로 전달).
   * 둘 중 하나라도 있으면 { from, until } 로 묶여 PortOne 에 전달된다.
   */
  from_date?: string;
  to_date?: string;
}

/**
 * 응답은 `{ success: true, ...result }` 형태로, result 는 PortOne
 * getPartnerSettlements / getPayouts 가 그대로 반환하는 외부 페이로드다.
 * TODO(web-kit): PortOne SDK 응답 스키마(items/paging 등)를 _shared/portone_client.ts 에서
 * 역산해 success 외 필드를 좁힐 것. 현재는 passthrough 로 외부 shape 를 보존한다.
 */
export const settlementQueryResponseSchema = z
  .object({
    success: z.literal(true),
  })
  .passthrough();
export type SettlementQueryResponse = z.infer<
  typeof settlementQueryResponseSchema
>;

export function settlementQuery(
  supabase: SessionSource,
  body: SettlementQueryRequest,
  options?: { signal?: AbortSignal },
): Promise<SettlementQueryResponse> {
  return callEdgeFunction(supabase, "settlement-query", body, {
    schema: settlementQueryResponseSchema,
    signal: options?.signal,
  });
}
