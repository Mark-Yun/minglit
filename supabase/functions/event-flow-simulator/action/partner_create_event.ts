// action/partner_create_event.ts — PartnerActionCreateEvent (EF: partner-manage-event)

import type { ActionDef } from "./_registry.ts";
import { registerAction } from "./_registry.ts";

const MIN_SCHEDULED_EVENTS = 2;
const EVENT_DURATION_MS = 2 * 60 * 60 * 1000;
const MIN_START_DELAY_DAYS = 7;
const START_DELAY_WINDOW_DAYS = 21;

type PartnerParty = {
  id: string;
  status?: string;
};

export const partnerCreateEventAction: ActionDef = {
  type: "partner_create_event",
  role: "partner",
  ef: "partner-manage-event",

  canExecute(state) {
    const myEvents = (state.myEvents as Array<{ status: string }>) ?? [];
    const myParties = ((state.myParties as PartnerParty[]) ?? []).filter(
      (party) => typeof party.id === "string" && party.status !== "closed",
    );
    if (myParties.length === 0) return false;
    const scheduledCount =
      myEvents.filter((e) => e.status === "scheduled").length;
    return scheduledCount < MIN_SCHEDULED_EVENTS;
  },

  buildPayload(state, rng) {
    const now = Date.now();
    const myParties = ((state.myParties as PartnerParty[]) ?? []).filter(
      (party) => typeof party.id === "string" && party.status !== "closed",
    );
    if (myParties.length === 0) {
      throw new Error(
        "partner_create_event.buildPayload called without an existing party",
      );
    }

    const party = myParties[Math.floor(rng.next() * myParties.length)];
    const startDelayDays = MIN_START_DELAY_DAYS +
      Math.floor(rng.next() * START_DELAY_WINDOW_DAYS);
    const startTime = new Date(now + startDelayDays * 86_400_000);
    const endTime = new Date(startTime.getTime() + EVENT_DURATION_MS);

    return {
      action: "create",
      party_id: party.id,
      event: {
        title: `Event Flow Simulator Event ${now}`,
        description: {
          ops: [{ insert: "Auto-generated tick simulation event\n" }],
        },
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
        min_confirmed_count: 4,
        max_participants: 20,
        metadata: { show_participant_list: true, visibility: "public" },
      },
      entry_groups: [
        {
          label: "남성",
          gender: "male",
          birth_year_min: 1990,
          birth_year_max: 2005,
        },
        {
          label: "여성",
          gender: "female",
          birth_year_min: 1990,
          birth_year_max: 2005,
        },
      ],
      tickets: [{ name: "일반", price: 15000, quantity: 20 }],
    };
  },
};

registerAction(partnerCreateEventAction);
