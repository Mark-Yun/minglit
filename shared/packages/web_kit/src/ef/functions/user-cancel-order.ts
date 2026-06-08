// user-cancel-order — 유저 주문 취소 + PortOne 환불 처리
// manifest: caller=user
// 역산 출처: supabase/functions/user-cancel-order/{index,input}.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface CancelOrderRequest {
  event_id: string;
  reason?: string;
}

export const cancelOrderResponseSchema = z.discriminatedUnion("type", [
  z.object({
    success: z.literal(true),
    type: z.literal("refunded"),
    data: z.object({ refund_amount: z.number() }),
  }),
  z.object({
    success: z.literal(true),
    type: z.literal("cancelled"),
  }),
  z.object({
    success: z.literal(true),
    type: z.literal("partner_refund_available"),
    data: z.object({
      application_id: z.string(),
      reason: z.string(),
      deadline_hours: z.number(),
    }),
  }),
]);
export type CancelOrderResponse = z.infer<typeof cancelOrderResponseSchema>;

export function userCancelOrder(
  supabase: SessionSource,
  body: CancelOrderRequest,
  options?: { signal?: AbortSignal },
): Promise<CancelOrderResponse> {
  return callEdgeFunction(supabase, "user-cancel-order", body, {
    schema: cancelOrderResponseSchema,
    signal: options?.signal,
  });
}
