// v2/action/apply.ts — UserActionApply (EF: apply-event)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

export const applyAction: ActionDef = {
  type: "user_apply",
  role: "user",
  ef: "apply-event",

  canExecute(state) {
    const apps = (state.myApplications as Array<{ event_id: string }>) ?? [];
    const events = (state.visibleEvents as Array<{ id: string; tickets?: unknown[] }>) ?? [];
    if (events.length === 0) return false;
    const appliedEventIds = new Set(apps.map((a) => a.event_id));
    // 신청 가능한 (티켓 있고 미신청) 이벤트 존재
    return events.some(
      (e) => !appliedEventIds.has(e.id) && (e.tickets?.length ?? 0) > 0,
    );
  },

  buildPayload(state, rng) {
    const apps = (state.myApplications as Array<{ event_id: string }>) ?? [];
    const events =
      (state.visibleEvents as Array<{ id: string; tickets?: Array<{ id: string }> }>) ?? [];
    const appliedEventIds = new Set(apps.map((a) => a.event_id));
    const candidates = events.filter(
      (e) => !appliedEventIds.has(e.id) && (e.tickets?.length ?? 0) > 0,
    );
    if (candidates.length === 0) {
      throw new Error("apply.buildPayload called when no candidate event — canExecute should have gated");
    }
    const idx = Math.floor(rng.next() * candidates.length);
    const event = candidates[idx];
    const ticket = event.tickets![0];
    return { event_id: event.id, ticket_id: ticket.id };
  },
};

registerAction(applyAction);
