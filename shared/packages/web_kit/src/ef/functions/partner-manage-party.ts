// partner-manage-party — 파티/장소/티켓템플릿 CRUD (action dispatch)
// manifest: caller=user (파트너 권한은 서버에서 requirePartnerPermission 으로 검사)
// 역산 출처: supabase/functions/partner-manage-party/index.ts + _handlers/*
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export type PartnerManagePartyAction =
  | "create"
  | "update"
  | "update_status"
  | "create_location"
  | "update_location"
  | "create_ticket_template"
  | "update_ticket_template"
  | "delete_ticket_template";

/**
 * action 별 payload 가 크게 달라 우선 느슨하게 타이핑.
 * TODO(web-kit): _handlers/{create,update,update_status,location,ticket_template}.ts 의
 * PARTY_FIELDS / LOCATION_FIELDS / 검증 로직을 역산해 action 별 request 타입으로 좁힐 것.
 */
export interface PartnerManagePartyRequest {
  action: PartnerManagePartyAction;
  /** create 필수 (multi-partner 유저 지원) */
  partner_id?: string;
  /** create/update — 최소 { title: string } + PARTY_FIELDS (TODO: 필드 확정) */
  party?: Record<string, unknown>;
  party_id?: string;
  location_id?: string;
  location?: Record<string, unknown>;
  [key: string]: unknown;
}

export const partnerManagePartyResponseSchema = z.object({
  success: z.literal(true),
  /** action=create 일 때 */
  party_id: z.string().optional(),
  /** action=create_location 일 때 */
  location_id: z.string().optional(),
  /** action=create_ticket_template 일 때 */
  ticket_template_id: z.string().optional(),
});
export type PartnerManagePartyResponse = z.infer<
  typeof partnerManagePartyResponseSchema
>;

export function partnerManageParty(
  supabase: SessionSource,
  body: PartnerManagePartyRequest,
  options?: { signal?: AbortSignal },
): Promise<PartnerManagePartyResponse> {
  return callEdgeFunction(supabase, "partner-manage-party", body, {
    schema: partnerManagePartyResponseSchema,
    signal: options?.signal,
  });
}
