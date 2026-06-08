// v2/action/apply.ts — UserActionApply (EF: apply-event)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";
import {
  isEventFull,
  isEventOpenForApplication,
  isTicketSoldOut,
} from "../../_shared/domains/event/availability.ts";

type TicketCandidate = {
  id: string;
  status?: string;
  quantity?: number;
  sold_count?: number;
};

type EventCandidate = {
  id: string;
  status?: string;
  current_participants?: number;
  max_participants?: number;
  tickets?: TicketCandidate[];
};

function isApplicationEvent(event: EventCandidate): boolean {
  if (
    typeof event.status !== "string" ||
    !isEventOpenForApplication(event.status)
  ) {
    return false;
  }
  if (
    typeof event.current_participants === "number" &&
    typeof event.max_participants === "number" &&
    isEventFull(event.current_participants, event.max_participants)
  ) {
    return false;
  }
  return true;
}

function isApplicationTicket(ticket: TicketCandidate): boolean {
  return ticket.status === "on_sale" &&
    typeof ticket.quantity === "number" &&
    typeof ticket.sold_count === "number" &&
    !isTicketSoldOut(ticket.sold_count, ticket.quantity);
}

function availableApplicationCandidates(events: EventCandidate[]) {
  return events.flatMap((event) => {
    if (!isApplicationEvent(event)) return [];
    const ticket = event.tickets?.find(isApplicationTicket);
    return ticket ? [{ event, ticket }] : [];
  });
}

export const applyAction: ActionDef = {
  type: "user_apply",
  role: "user",
  ef: "apply-event",

  canExecute(state) {
    const apps = (state.myApplications as Array<{ event_id: string }>) ?? [];
    const events = (state.visibleEvents as EventCandidate[]) ?? [];
    if (events.length === 0) return false;
    const appliedEventIds = new Set(apps.map((a) => a.event_id));
    // 신청 가능한 (티켓 있고 미신청) 이벤트 존재
    return availableApplicationCandidates(events).some(
      ({ event }) => !appliedEventIds.has(event.id),
    );
  },

  buildPayload(state, rng) {
    const apps = (state.myApplications as Array<{ event_id: string }>) ?? [];
    const events = (state.visibleEvents as EventCandidate[]) ?? [];
    const appliedEventIds = new Set(apps.map((a) => a.event_id));
    const candidates = availableApplicationCandidates(events).filter(
      ({ event }) => !appliedEventIds.has(event.id),
    );
    if (candidates.length === 0) {
      throw new Error(
        "apply.buildPayload called when no candidate event — canExecute should have gated",
      );
    }
    const idx = Math.floor(rng.next() * candidates.length);
    const { event, ticket } = candidates[idx];
    return { event_id: event.id, ticket_id: ticket.id };
  },
};

registerAction(applyAction);
