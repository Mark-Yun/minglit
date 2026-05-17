// core/transport.ts — 실 EF 호출 Transport + direct DB write 분기 (block 액션)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Action, ActorId } from "./types.ts";
import type { Transport } from "./cascade.ts";
import { callEdgeFunction } from "./auth.ts";

export interface EFTransportConfig {
  supabase: SupabaseClient;
  supabaseUrl: string;
  /** actorId → JWT 토큰. cascade 실행 전 모든 actor 의 토큰을 미리 채움 */
  tokenByActor: Map<ActorId, string>;
}

/**
 * 실 EF 호출 transport. action.ef 가 정의돼 있으면 callEdgeFunction 으로 POST.
 * action.ef 가 undefined 인 경우 (현재: block 액션) supabase client 로 direct DB write.
 */
export class EFTransport implements Transport {
  constructor(private cfg: EFTransportConfig) {}

  async execute(action: Action) {
    const token = this.cfg.tokenByActor.get(action.actorId);
    if (!token) {
      return { ok: false, status: 0, error: `no token for actor ${action.actorId}` };
    }

    // direct DB write 분기 (block 액션)
    if (action.type === "user_block") {
      const partyId = action.payload.party_id as string;
      const { data: party } = await this.cfg.supabase
        .from("parties")
        .select("partner_id")
        .eq("id", partyId)
        .maybeSingle();
      if (!party) {
        return { ok: false, status: 404, error: `party ${partyId} not found` };
      }
      const partnerId = (party as { partner_id: string }).partner_id;
      const { error } = await this.cfg.supabase
        .from("social_interactions")
        .upsert({
          user_id: action.actorId,
          target_id: partnerId,
          target_type: "partner",
          interaction_type: "block",
        });
      if (error) {
        return { ok: false, status: 500, error: error.message };
      }
      return { ok: true, status: 200 };
    }

    // 일반 EF 호출
    if (!action.ef) {
      return { ok: false, status: 0, error: `action ${action.type} has no ef` };
    }
    const res = await callEdgeFunction(
      this.cfg.supabaseUrl,
      action.ef,
      action.payload,
      token,
    );
    return {
      ok: res.status >= 200 && res.status < 300,
      status: res.status,
      data: res.data,
    };
  }
}
