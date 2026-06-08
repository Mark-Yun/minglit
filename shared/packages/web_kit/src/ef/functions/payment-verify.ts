// payment-verify — 결제 완료 검증 (PortOne V1)
// manifest: caller=user
// 역산 출처: supabase/functions/payment-verify/{index,input}.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface PaymentVerifyRequest {
  imp_uid: string;
  merchant_uid: string;
}

export const paymentVerifyResponseSchema = z.object({
  success: z.literal(true),
  /** 정상 검증 시 존재. 이미 처리된 건이면 대신 message 가 옴 */
  imp_uid: z.string().optional(),
  /** "Already processed" — 중복 검증 호출 시 */
  message: z.string().optional(),
});
export type PaymentVerifyResponse = z.infer<typeof paymentVerifyResponseSchema>;

export function paymentVerify(
  supabase: SessionSource,
  body: PaymentVerifyRequest,
  options?: { signal?: AbortSignal },
): Promise<PaymentVerifyResponse> {
  return callEdgeFunction(supabase, "payment-verify", body, {
    schema: paymentVerifyResponseSchema,
    signal: options?.signal,
  });
}
