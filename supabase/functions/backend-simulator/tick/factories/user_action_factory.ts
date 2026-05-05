// tick/factories/user_action_factory.ts — UserActionFactory: generates per-tick user actions (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { TickConfig } from "../tick_types.ts";
import type { SimAction } from "../sim_action.ts";
import { callEdgeFunction } from "../../sim_auth.ts";
import { UserActionApplyEvent } from "../actions/user_action_apply.ts";
import { UserActionRefund } from "../actions/user_action_refund.ts";
import { UserActionCheckin } from "../actions/user_action_checkin.ts";
import { UserActionVote } from "../actions/user_action_vote.ts";

/**
 * Generates the set of SimActions a user should perform in the current tick.
 *
 * Decision logic:
 * - Queries the event feed to find apply candidates
 * - Reads existing applications to decide refund / checkin / vote actions
 * - Respects config.maxAppsPerUser, config.negativeRate, config.checkinRate
 */
export class UserActionFactory {
  constructor(
    private userId: string,
    private token: string,
    private supabaseUrl: string,
    private config: TickConfig,
  ) {}

  async generate(supabase: SupabaseClient): Promise<SimAction[]> {
    const actions: SimAction[] = [];

    // 1. Discover events via feed EF
    const feedRes = await callEdgeFunction(
      this.supabaseUrl,
      "user-event-feed",
      { limit: 20 },
      this.token,
    );
    const feedEvents =
      ((feedRes.data as Record<string, unknown>)?.events as Array<Record<string, unknown>>) ?? [];

    // Fix #2131: include events.start_time in event_applications query for refund eligibility
    const { data: myApps, error: myAppsError } = await supabase
      .from("event_applications")
      .select("id, event_id, status, events(status, start_time)")
      .eq("user_id", this.userId);

    if (myAppsError) throw new Error(`Failed to fetch applications: ${myAppsError.message}`);

    const appliedIds = new Set((myApps ?? []).map((a) => a.event_id as string));
    let activeAppCount = (myApps ?? []).filter(
      (a) => (a.status as string) !== "cancelled",
    ).length;

    // 3. Apply to un-applied events from feed (up to maxAppsPerUser)
    for (const event of feedEvents) {
      if (appliedIds.has(event.id as string)) continue;
      if (activeAppCount >= this.config.maxAppsPerUser) break;
      const tickets = (event.tickets as Array<Record<string, unknown>>) ?? [];
      if (tickets.length === 0) continue;
      actions.push(
        new UserActionApplyEvent(
          this.userId,
          event.id as string,
          tickets[0].id as string,
          this.token,
        ),
      );
      activeAppCount++;
    }

    // Fix #2131: Fetch refund policy from DB to avoid hardcoded drift vs. user-cancel-order EF.
    // Fallback to 7 days if RPC fails (same default as EF).
    const { data: refundPolicy } = await supabase.rpc("get_current_policy", { p_key: "refund" });
    const cutoffDays = (refundPolicy as Record<string, number> | null)?.cutoff_days ?? 7;
    const cutoffMs = cutoffDays * 24 * 60 * 60 * 1000;

    // 4. For existing applications, decide behavior based on DB state
    for (const app of (myApps ?? [])) {
      // Fix #1415: app.events is typed as { status: any }[] by PostgREST but the join returns
      // a single object for a to-one FK. Use `unknown` intermediary to avoid TS2352.
      const eventInfo = app.events as unknown as { status: string; start_time: string } | null;
      const eventStatus = eventInfo?.status ?? "";
      const appId = app.id as string;
      const eventId = app.event_id as string;

      // Approved + scheduled → maybe refund
      if (app.status === "approved" && eventStatus === "scheduled") {
        // Fix #2131: Only attempt refund when within EF cutoff window (cutoffDays from policy).
        // Simulator doesn't track paid_at so grace-period path is excluded;
        // selecting outside the cutoff caused false-positive 400 failures.
        const eventStart = eventInfo?.start_time ? new Date(eventInfo.start_time) : null;
        const refundEligible = eventStart !== null && eventStart.getTime() - Date.now() >= cutoffMs;
        if (refundEligible && Math.random() < this.config.negativeRate) {
          actions.push(new UserActionRefund(this.userId, appId, eventId, this.token));
        }
      }

      // Approved + active → maybe checkin
      if (app.status === "approved" && eventStatus === "active") {
        const { data: participant, error: participantError } = await supabase
          .from("event_participants")
          .select("id, status")
          .eq("event_id", eventId)
          .eq("user_id", this.userId)
          .maybeSingle();

        if (participantError) throw new Error(`Failed to fetch participant: ${participantError.message}`);

        if (participant && (participant.status as string) === "ticket_issued") {
          if (Math.random() < this.config.checkinRate) {
            actions.push(
              new UserActionCheckin(
                this.userId,
                eventId,
                participant.id as string,
                this.token,
              ),
            );
          }
          // else: no-show — natural behavior, no action generated
        }
      }

      // Checked in + ongoing → vote on other checked-in participants
      if (eventStatus === "ongoing") {
        const { data: participant, error: ongoingParticipantError } = await supabase
          .from("event_participants")
          .select("status")
          .eq("event_id", eventId)
          .eq("user_id", this.userId)
          .maybeSingle();

        if (ongoingParticipantError) throw new Error(`Failed to fetch participant status: ${ongoingParticipantError.message}`);

        if ((participant?.status as string) === "checked_in") {
          // Get other checked-in participants as candidates (up to 5)
          const { data: candidates, error: candidatesError } = await supabase
            .from("event_participants")
            .select("user_id")
            .eq("event_id", eventId)
            .eq("status", "checked_in")
            .neq("user_id", this.userId)
            .limit(5);

          if (candidatesError) throw new Error(`Failed to fetch vote candidates: ${candidatesError.message}`);

          for (const c of (candidates ?? [])) {
            // Only vote if not already voted for this candidate
            const { data: existingVote, error: existingVoteError } = await supabase
              .from("match_votes")
              .select("id")
              .eq("event_id", eventId)
              .eq("voter_id", this.userId)
              .eq("candidate_id", c.user_id as string)
              .maybeSingle();

            if (existingVoteError) throw new Error(`Failed to fetch existing vote: ${existingVoteError.message}`);

            if (!existingVote) {
              actions.push(
                new UserActionVote(
                  this.userId,
                  eventId,
                  c.user_id as string,
                  this.token,
                ),
              );
            }
          }
        }
      }
    }

    return actions;
  }
}
