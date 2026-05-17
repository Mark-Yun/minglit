// action/vote.ts — UserActionVote (EF: user-cast-vote)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const voteAction: ActionDef = {
  type: "user_vote",
  role: "user",
  ef: "user-cast-vote",

  canExecute(state) {
    const participations =
      (state.myParticipations as Array<{
        event_id: string;
        status: string;
      }>) ?? [];
    const events =
      (state.visibleEvents as Array<{ id: string; status: string }>) ?? [];

    // vote 가능 = ongoing event 에 checked_in 한 본인 + 그 event 에 다른 checked_in
    // PoC: observable 에 다른 참가자 정보 없음 — 본인이 ongoing+checked_in 인지만 게이트
    // 실제 sampling 은 transport 단계에서 candidate 부재 시 EF 가 거절
    const ongoingEventIds = new Set(
      events.filter((e) => e.status === "ongoing").map((e) => e.id),
    );
    return participations.some(
      (p) => p.status === "checked_in" && ongoingEventIds.has(p.event_id),
    );
  },

  buildPayload(state, rng) {
    const participations =
      (state.myParticipations as Array<{
        event_id: string;
        status: string;
      }>) ?? [];
    const events =
      (state.visibleEvents as Array<{ id: string; status: string }>) ?? [];
    const ongoingEventIds = new Set(
      events.filter((e) => e.status === "ongoing").map((e) => e.id),
    );
    const candidates = participations.filter(
      (p) => p.status === "checked_in" && ongoingEventIds.has(p.event_id),
    );
    if (candidates.length === 0) {
      throw new Error("vote.buildPayload called when no candidate — canExecute should have gated");
    }
    const idx = Math.floor(rng.next() * candidates.length);
    // candidate_id 는 transport 가 동일 event 내 다른 참가자에서 sampling (snapshot 외 정보 필요)
    return { event_id: candidates[idx].event_id, candidate_id: null };
  },
};

registerAction(voteAction);
