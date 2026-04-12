// tick/factories/partner_action_factory.ts — PartnerActionFactory (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { TickConfig } from "../tick_types.ts";
import type { SimAction } from "../sim_action.ts";
import { PartnerActionApprove } from "../actions/partner_action_approve.ts";
import { PartnerActionReject } from "../actions/partner_action_reject.ts";
import { PartnerActionCreateEvent } from "../actions/partner_action_create.ts";

/**
 * Generates partner actions for a single tick:
 * - Approve 90% / reject 10% of pending_review applications for this partner's events
 * - Create a new party+event if scheduled events fall below config.minScheduledEvents
 */
export class PartnerActionFactory {
  constructor(
    private partnerId: string,
    private token: string,
    private config: TickConfig,
  ) {}

  async generate(supabase: SupabaseClient): Promise<SimAction[]> {
    const actions: SimAction[] = [];

    // 1. Get all party IDs belonging to this partner
    const { data: parties } = await supabase
      .from("parties")
      .select("id")
      .eq("partner_id", this.partnerId);

    const partyRows = (parties ?? []) as { id: string }[];
    const partyIds = partyRows.map((p) => p.id);

    if (partyIds.length === 0) {
      // No parties yet — create one immediately
      actions.push(new PartnerActionCreateEvent(this.partnerId, this.token));
      return actions;
    }

    // 2. Get event IDs for this partner's parties
    const { data: events } = await supabase
      .from("events")
      .select("id")
      .in("party_id", partyIds);

    const eventRows = (events ?? []) as { id: string }[];
    const eventIds = eventRows.map((e) => e.id);

    if (eventIds.length > 0) {
      // 3. Find pending_review applications for partner's events
      const { data: pending } = await supabase
        .from("event_applications")
        .select("id")
        .eq("status", "pending_review")
        .in("event_id", eventIds);

      // Approve 90%, reject 10%
      for (const app of (pending ?? []) as { id: string }[]) {
        if (Math.random() < 0.9) {
          actions.push(new PartnerActionApprove(this.partnerId, app.id, this.token));
        } else {
          actions.push(new PartnerActionReject(this.partnerId, app.id, this.token));
        }
      }
    }

    // 4. Check scheduled events count — create new party+event if below minimum
    const { data: scheduled } = await supabase
      .from("events")
      .select("id")
      .eq("status", "scheduled")
      .in("party_id", partyIds);

    if ((scheduled ?? []).length < this.config.minScheduledEvents) {
      actions.push(new PartnerActionCreateEvent(this.partnerId, this.token));
    }

    return actions;
  }
}
