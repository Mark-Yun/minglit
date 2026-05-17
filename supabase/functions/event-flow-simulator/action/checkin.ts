// action/checkin.ts — UserActionCheckin (EF: event-checkin)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const checkinAction: ActionDef = {
  type: "user_checkin",
  role: "user",
  ef: "event-checkin",

  canExecute(state) {
    const participations =
      (state.myParticipations as Array<{
        id: string;
        event_id: string;
        status: string;
      }>) ?? [];
    const events =
      (state.visibleEvents as Array<{ id: string; status: string }>) ?? [];

    // checkin 가능 = ticket_issued participant 가 있고 event 가 active
    const activeEventIds = new Set(
      events.filter((e) => e.status === "active").map((e) => e.id),
    );
    return participations.some(
      (p) => p.status === "ticket_issued" && activeEventIds.has(p.event_id),
    );
  },

  buildPayload(state, rng) {
    const participations =
      (state.myParticipations as Array<{
        id: string;
        event_id: string;
        status: string;
      }>) ?? [];
    const events =
      (state.visibleEvents as Array<{ id: string; status: string }>) ?? [];
    const activeEventIds = new Set(
      events.filter((e) => e.status === "active").map((e) => e.id),
    );
    const candidates = participations.filter(
      (p) => p.status === "ticket_issued" && activeEventIds.has(p.event_id),
    );
    if (candidates.length === 0) {
      throw new Error("checkin.buildPayload called when no candidate — canExecute should have gated");
    }
    const idx = Math.floor(rng.next() * candidates.length);
    return { event_id: candidates[idx].event_id, participant_id: candidates[idx].id };
  },
};

registerAction(checkinAction);
