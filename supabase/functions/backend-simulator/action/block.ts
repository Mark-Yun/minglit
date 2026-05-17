// action/block.ts — UserActionBlock (direct DB write — social_interactions upsert)
//
// 본 액션은 EF 가 아닌 client-side direct write (현 minglit 의 social_repository 패턴).
// cascade 의 cross-EF 가드 (blocking invariant) 와 연동 — block 이 발생해야 invariant 가
// 의미 있는 violation 탐지 가능.

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const blockAction: ActionDef = {
  type: "user_block",
  role: "user",
  ef: undefined,            // EF 가 아니라 direct DB write — transport 가 분기 처리

  canExecute(state) {
    const apps = (state.myApplications as Array<{ event_id: string; status: string }>) ?? [];
    const events = (state.visibleEvents as Array<{
      id: string;
      party_id: string;
    }>) ?? [];
    const blocks =
      (state.myBlocks as Array<{ target_id: string; target_type: string }>) ?? [];

    // block 가능 = 신청한 event 의 partner 중 아직 block 안 한 게 있음
    const eventById = new Map(events.map((e) => [e.id, e]));
    const blockedPartnerIds = new Set(
      blocks
        .filter((b) => b.target_type === "partner")
        .map((b) => b.target_id),
    );
    // observable 에 partner_id 가 없으니 event.party_id 로 대체 후 transport 가 매핑
    return apps.some((app) => {
      const ev = eventById.get(app.event_id);
      return ev !== undefined && !blockedPartnerIds.has(ev.party_id);
    });
  },

  buildPayload(state, rng) {
    const apps = (state.myApplications as Array<{ event_id: string; status: string }>) ?? [];
    const events = (state.visibleEvents as Array<{ id: string; party_id: string }>) ?? [];
    const blocks =
      (state.myBlocks as Array<{ target_id: string; target_type: string }>) ?? [];
    const eventById = new Map(events.map((e) => [e.id, e]));
    const blockedPartnerIds = new Set(
      blocks
        .filter((b) => b.target_type === "partner")
        .map((b) => b.target_id),
    );
    const candidateEvents = apps
      .map((a) => eventById.get(a.event_id))
      .filter((e): e is { id: string; party_id: string } =>
        e !== undefined && !blockedPartnerIds.has(e.party_id)
      );
    if (candidateEvents.length === 0) {
      throw new Error("block.buildPayload called when no candidate — canExecute should have gated");
    }
    const idx = Math.floor(rng.next() * candidateEvents.length);
    return {
      party_id: candidateEvents[idx].party_id,
      // transport 가 party_id → partner_id 변환 + social_interactions upsert
    };
  },
};

registerAction(blockAction);
