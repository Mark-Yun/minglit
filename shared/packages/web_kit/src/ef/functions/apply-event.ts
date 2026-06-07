// apply-event — 유저 이벤트 신청 (무료/유료 분기, verification_data 처리)
// manifest: caller=user · rate_limit(user, 5cap) · idempotency REQUIRED (Idempotency-Key 헤더)
// 역산 출처: supabase/functions/apply-event/index.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface ApplyEventVerificationItem {
  verification_id: string;
  data: Record<string, unknown>;
}

/** 신규 array 포맷 권장 — legacy 단건 포맷(verification_id/data 직접)도 서버가 수용 */
export interface ApplyEventVerificationData {
  partner_id?: string;
  verifications?: ApplyEventVerificationItem[];
  /** @deprecated legacy 단건 포맷 */
  verification_id?: string;
  /** @deprecated legacy 단건 포맷 */
  data?: Record<string, unknown>;
}

export interface ApplyEventRequest {
  event_id: string;
  ticket_id: string;
  verification_data?: ApplyEventVerificationData;
}

export const applyEventResponseSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("free"),
    application_id: z.string(),
  }),
  z.object({
    type: z.literal("paid"),
    application_id: z.string(),
    /** 현재 구현은 application_id 와 동일 값 */
    order_id: z.string(),
    payment_amount: z.number(),
  }),
]);
export type ApplyEventResponse = z.infer<typeof applyEventResponseSchema>;

export function applyEvent(
  supabase: SessionSource,
  body: ApplyEventRequest,
  options?: { idempotencyKey?: string; signal?: AbortSignal },
): Promise<ApplyEventResponse> {
  return callEdgeFunction(supabase, "apply-event", body, {
    schema: applyEventResponseSchema,
    // manifest 가 idempotency 필수 — 미지정 시 호출 단위로 새 키 생성
    idempotencyKey: options?.idempotencyKey ?? crypto.randomUUID(),
    signal: options?.signal,
  });
}
