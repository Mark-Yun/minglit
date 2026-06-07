// user-create-order — 유저 결제 주문 생성 (apply_event RPC 경유)
// manifest: caller=user
// 역산 출처: supabase/functions/user-create-order/{index,input}.ts,
//           _shared/domains/order/create_order_policy.ts (CreateOrderVerificationData)
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface CreateOrderRequest {
  event_id: string;
  ticket_id: string;
  /** apply-event 와 달리 단건 포맷만 수용 */
  verification_data?: {
    verification_id: string;
    data: Record<string, unknown>;
  };
}

export const createOrderResponseSchema = z.object({
  success: z.literal(true),
  application_id: z.string(),
  amount: z.number(),
  requires_payment: z.boolean(),
  ticket_name: z.string(),
});
export type CreateOrderResponse = z.infer<typeof createOrderResponseSchema>;

export function userCreateOrder(
  supabase: SessionSource,
  body: CreateOrderRequest,
  options?: { signal?: AbortSignal },
): Promise<CreateOrderResponse> {
  return callEdgeFunction(supabase, "user-create-order", body, {
    schema: createOrderResponseSchema,
    signal: options?.signal,
  });
}
