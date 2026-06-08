// payment-cancel — 결제 취소 및 환불 처리 (유저 직접 요청 경로)
// manifest: caller=user,system (웹 클라이언트는 user 경로만 사용)
// 역산 출처: supabase/functions/payment-cancel/index.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface PaymentCancelRequest {
  payment_id: string;
  reason?: string;
  /** 부분 환불 금액 — 미지정 시 전액 */
  amount?: number;
  /** PortOne 취소 가능 잔액 검증값 */
  checksum?: number;
}

export const paymentCancelResponseSchema = z.object({
  success: z.literal(true),
  // TODO(web-kit): PortOne cancel 응답 원본 passthrough — 필드 계약 미확정.
  // 필요 필드가 생기면 _shared/refund_utils.ts 의 executeRefund 반환을 역산해 좁힐 것.
  data: z.record(z.string(), z.unknown()),
});
export type PaymentCancelResponse = z.infer<typeof paymentCancelResponseSchema>;

export function paymentCancel(
  supabase: SessionSource,
  body: PaymentCancelRequest,
  options?: { signal?: AbortSignal },
): Promise<PaymentCancelResponse> {
  return callEdgeFunction(supabase, "payment-cancel", body, {
    schema: paymentCancelResponseSchema,
    signal: options?.signal,
  });
}
