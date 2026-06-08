// payment-verify — 결제 완료 검증 (PortOne V1 / V2)
// manifest: caller=user
// 역산 출처: supabase/functions/payment-verify/{index,input}.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface PaymentVerifyRequest {
  imp_uid: string;
  merchant_uid: string;
}

export interface PaymentVerifyPortoneV2Request {
  provider: "portone_v2";
  payment_id: string;
}

export const paymentVerifyResponseSchema = z.object({
  success: z.literal(true),
  type: z.enum(["paid", "already_processed"]).optional(),
  /** 정상 검증 시 존재. 이미 처리된 건이면 대신 message 가 옴 */
  imp_uid: z.string().optional(),
  /** PortOne V2 정상 검증 시 존재 */
  payment_id: z.string().optional(),
  application_id: z.string().optional(),
  purchase_url: z.string().optional(),
  /** "Already processed" — 중복 검증 호출 시 */
  message: z.string().optional(),
});
export type PaymentVerifyResponse = z.infer<typeof paymentVerifyResponseSchema>;

export function paymentVerify(
  supabase: SessionSource,
  body: PaymentVerifyRequest | PaymentVerifyPortoneV2Request,
  options?: { signal?: AbortSignal },
): Promise<PaymentVerifyResponse> {
  return callEdgeFunction(supabase, "payment-verify", body, {
    schema: paymentVerifyResponseSchema,
    signal: options?.signal,
  });
}
