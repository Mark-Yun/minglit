// partner-manage-event — 파트너 이벤트 관리 (생성/수정/상태변경/티켓)
// manifest: caller=user (파트너 권한은 서버에서 requirePartnerPermission 으로 검사)
// 역산 출처: supabase/functions/partner-manage-event/index.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export type PartnerManageEventAction =
  | "create"
  | "update"
  | "update_status"
  | "update_tickets"
  | "create_ticket";

/**
 * action 별 payload 가 크게 달라 우선 느슨하게 타이핑.
 * TODO(web-kit): partner-manage-event/index.ts 의 handleCreate/handleUpdate/
 * handleUpdateStatus/handleUpdateTickets/handleCreateTicket 검증 로직을 역산해
 * action 별 request 타입으로 좁힐 것 (event 필드, entry_groups, tickets 등).
 */
export interface PartnerManageEventRequest {
  action: PartnerManageEventAction;
  /** create 필수 */
  party_id?: string;
  /** update/update_status/update_tickets/create_ticket 대상 */
  event_id?: string;
  /** create/update — 최소 { start_time, end_time } (ISO 문자열) + 그 외 필드 TODO */
  event?: {
    start_time?: string;
    end_time?: string;
    [key: string]: unknown;
  };
  /** TODO: entry group 레코드 형태 확정 */
  entry_groups?: unknown[];
  /** TODO: ticket 레코드 형태 확정 */
  tickets?: unknown[];
  [key: string]: unknown;
}

export const partnerManageEventResponseSchema = z.object({
  success: z.literal(true),
  /** action=create 일 때 */
  event_id: z.string().optional(),
  /** action=create_ticket 일 때 */
  ticket_id: z.string().optional(),
});
export type PartnerManageEventResponse = z.infer<
  typeof partnerManageEventResponseSchema
>;

export function partnerManageEvent(
  supabase: SessionSource,
  body: PartnerManageEventRequest,
  options?: { signal?: AbortSignal },
): Promise<PartnerManageEventResponse> {
  return callEdgeFunction(supabase, "partner-manage-event", body, {
    schema: partnerManageEventResponseSchema,
    signal: options?.signal,
  });
}
