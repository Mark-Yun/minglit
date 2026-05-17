// action/refund.ts — UserActionRefund (EF: user-cancel-order)
//
// Critical EF — cross-EF 가드 대상 (blocking invariant 와 연동).

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

export const refundAction: ActionDef = {
  type: "user_refund",
  role: "user",
  ef: "user-cancel-order",

  canExecute(state) {
    const apps = (state.myApplications as Array<{
      id: string;
      event_id: string;
      status: string;
    }>) ?? [];
    const events = (state.visibleEvents as Array<{
      id: string;
      status: string;
      start_time: string;
    }>) ?? [];

    // 환불 가능 = approved or paid + scheduled event + 7일 이상 남음 (Fix #2131 정책)
    const eventById = new Map(events.map((e) => [e.id, e]));
    return apps.some((app) => {
      if (!["approved", "paid"].includes(app.status)) return false;
      const ev = eventById.get(app.event_id);
      if (!ev || ev.status !== "scheduled") return false;
      const start = new Date(ev.start_time).getTime();
      return start - Date.now() >= SEVEN_DAYS_MS;
    });
  },

  buildPayload(state, rng) {
    const apps = (state.myApplications as Array<{
      id: string;
      event_id: string;
      status: string;
    }>) ?? [];
    const events = (state.visibleEvents as Array<{
      id: string;
      status: string;
      start_time: string;
    }>) ?? [];
    const eventById = new Map(events.map((e) => [e.id, e]));
    const candidates = apps.filter((app) => {
      if (!["approved", "paid"].includes(app.status)) return false;
      const ev = eventById.get(app.event_id);
      if (!ev || ev.status !== "scheduled") return false;
      const start = new Date(ev.start_time).getTime();
      return start - Date.now() >= SEVEN_DAYS_MS;
    });
    if (candidates.length === 0) {
      throw new Error("refund.buildPayload called when no candidate — canExecute should have gated");
    }
    const idx = Math.floor(rng.next() * candidates.length);
    return { event_id: candidates[idx].event_id };
  },
};

registerAction(refundAction);
