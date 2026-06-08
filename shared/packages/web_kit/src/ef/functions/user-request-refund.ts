// user-request-refund — 유저 파트너 환불 요청 생성
// manifest: caller=user
// 역산 출처: supabase/functions/user-request-refund/{index,input}.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface UserRequestRefundRequest {
  application_id: string;
  reason_code: "schedule_change" | "health" | "other";
  reason_text?: string;
}

export const userRequestRefundResponseSchema = z.object({
  success: z.literal(true),
  type: z.literal("partner_refund_requested"),
  request: z.object({
    id: z.string(),
    application_id: z.string(),
    status: z.literal("pending"),
    requested_at: z.string(),
    response_deadline_at: z.string(),
  }),
});
export type UserRequestRefundResponse = z.infer<
  typeof userRequestRefundResponseSchema
>;

export function userRequestRefund(
  supabase: SessionSource,
  body: UserRequestRefundRequest,
  options?: { signal?: AbortSignal },
): Promise<UserRequestRefundResponse> {
  return callEdgeFunction(supabase, "user-request-refund", body, {
    schema: userRequestRefundResponseSchema,
    signal: options?.signal,
  });
}
