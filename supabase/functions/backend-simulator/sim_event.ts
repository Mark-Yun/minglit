// sim_event.ts — Phase 5: Check-in + Matching + Event Completion

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import {
  simAssertMatchPairCreated,
  simAssertCheckinRatio,
} from "./sim_assertions.ts";
import { getSimUserToken, callEdgeFunction } from "./sim_auth.ts";

async function allSettledInBatches<T>(
  items: T[],
  batchSize: number,
  worker: (item: T) => Promise<void>,
): Promise<PromiseSettledResult<void>[]> {
  const results: PromiseSettledResult<void>[] = [];
  for (let i = 0; i < items.length; i += batchSize) {
    results.push(
      ...(await Promise.allSettled(items.slice(i, i + batchSize).map(worker))),
    );
  }
  return results;
}

export interface SimEventResult {
  checkedInParticipantIds: string[];
  noShowParticipantIds: string[];
  matchPairs: Array<{ userId1: string; userId2: string; eventId: string }>;
  completedEventIds: string[];
  assertions: SimAssertionResult[];
}

// ─────────────────────────────────────────────────────────
// simCheckin
// ─────────────────────────────────────────────────────────

/**
 * Simulates check-in for participants across given events.
 * - checkinRate (default 0.7) fraction → status='checked_in' via event-checkin EF
 * - remaining fraction → status='no_show' via direct DB (no EF for passive state)
 *
 * EF is the only path for checked_in. supabaseUrl/anonKey are required.
 * Missing credentials cause an immediate error.
 *
 * Asserts checkin ratio within ±0.15 tolerance.
 */
export async function simCheckin(
  supabase: SupabaseClient,
  eventIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  checkinRate: number = 0.7,
  supabaseUrl?: string,
  anonKey?: string,
): Promise<{ checkedInParticipantIds: string[]; noShowParticipantIds: string[]; assertions: SimAssertionResult[] }> {
  const checkedInParticipantIds: string[] = [];
  const noShowParticipantIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";

  if (eventIds.length === 0) {
    log({ level: "info", phase: "checkin", step: "skip", message: "No events to process" });
    return { checkedInParticipantIds, noShowParticipantIds, assertions };
  }

  // Fix #1281: EF-only — supabaseUrl/anonKey are required for checked_in path.
  // Fix #1283: strict parameter removed — fail fast always.
  if (!supabaseUrl || !anonKey) {
    throw new Error("supabaseUrl and anonKey are required for event-checkin EF");
  }

  // Fix #531: Process events in batches to prevent curl 120s timeout.
  // Previously sequential processing caused N * (participants * EF calls) ≈ 120s+.
  const results = await allSettledInBatches(eventIds, 10, async (eventId) => {
    // Query participants with ticket_issued or checked_in status
    const { data: participants, error: fetchErr } = await supabase
      .from("event_participants")
      .select("id, user_id, status")
      .eq("event_id", eventId);

    if (fetchErr) {
      log({ level: "error", phase: "checkin", step: "fetch_participants", message: `Failed to fetch participants for event ${eventId}: ${fetchErr.message}` });
      return;
    }

    const rows = (participants ?? []) as Array<{ id: string; user_id: string; status: string }>;
    const eligible = rows.filter((p) => p.status === "ticket_issued" || p.status === "checked_in");

    if (eligible.length === 0) {
      log({ level: "info", phase: "checkin", step: "no_participants", message: `No eligible participants for event ${eventId}` });
      return;
    }

    const splitIndex = Math.floor(eligible.length * checkinRate);

    for (let i = 0; i < eligible.length; i++) {
      const participant = eligible[i];
      const newStatus = i < splitIndex ? "checked_in" : "no_show";

      if (newStatus === "checked_in") {
        if (supabaseUrl && anonKey) {
          // Primary path: use event-checkin EF with user token
          const { data: profileData } = await supabase
            .from("user_profiles")
            .select("username")
            .eq("id", participant.user_id)
            .maybeSingle();
          const username = (profileData as { username?: string } | null)?.username;

          if (username && !username.startsWith("partner_")) {
            const userEmail = `${username}@test.com`;
            try {
              const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
              const efResult = await callEdgeFunction(supabaseUrl, "event-checkin", {
                event_id: eventId,
                participant_id: participant.id,
              }, userToken);

              if (efResult.status === 200) {
                checkedInParticipantIds.push(participant.id);
                log({ level: "info", phase: "checkin", step: "ef_checkin", message: `Checked in participant ${participant.id} via EF` });
                continue;
              } else {
                // Fix #1281: EF failure is always an error — no silent fallback
                throw new Error(`event-checkin EF returned ${efResult.status} for participant ${participant.id}`);
              }
            } catch (authErr) {
              // Fix #1281: propagate auth/EF errors — checked_in via direct DB is removed
              throw new Error(`event-checkin EF failed for participant ${participant.id} (${username}): ${String(authErr)}`);
            }
          } else {
            // Fix #1281: Partner user or no username — use direct DB as these accounts can't acquire user tokens
            const { error: updErr } = await supabase
              .from("event_participants")
              .update({ status: "checked_in" })
              .eq("id", participant.id);

            if (updErr) {
              log({ level: "error", phase: "checkin", step: "update_participant", message: `Failed to update partner participant ${participant.id}: ${updErr.message}` });
              continue;
            }

            checkedInParticipantIds.push(participant.id);
            log({ level: "info", phase: "checkin", step: "direct_checkin", message: `Checked in partner participant ${participant.id} via direct DB (no user token available)` });
            continue;
          }
        }
      }

      // no_show: direct DB update — no EF for passive state (batch/cron op in production too)
      const { error: updErr } = await supabase
        .from("event_participants")
        .update({ status: "no_show" })
        .eq("id", participant.id);

      if (updErr) {
        log({ level: "error", phase: "checkin", step: "update_participant", message: `Failed to update participant ${participant.id}: ${updErr.message}` });
        continue;
      }

      noShowParticipantIds.push(participant.id);
    }

    // Assert checkin ratio — use dynamic tolerance for small participant counts
    const tolerance = Math.max(0.15, 1 / Math.max(eligible.length, 1));
    const ratioAssertion = await simAssertCheckinRatio(supabase, eventId, checkinRate, tolerance);
    assertions.push(ratioAssertion);

    log({
      level: "info",
      phase: "checkin",
      step: "done",
      message: `Event ${eventId}: ${splitIndex} checked_in, ${eligible.length - splitIndex} no_show`,
      data: { eventId, checkedIn: splitIndex, noShow: eligible.length - splitIndex },
    });
  });

  for (const r of results) {
    if (r.status === "rejected") {
      log({ level: "error", phase: "checkin", step: "checkin_loop", message: `Unexpected error: ${String(r.reason)}` });
    }
  }

  log({
    level: "info",
    phase: "checkin",
    step: "complete",
    message: `Phase 5 checkin complete: ${checkedInParticipantIds.length} checked_in, ${noShowParticipantIds.length} no_show`,
    data: { checkedInCount: checkedInParticipantIds.length, noShowCount: noShowParticipantIds.length },
  });

  return { checkedInParticipantIds, noShowParticipantIds, assertions };
}

// ─────────────────────────────────────────────────────────
// simMatch
// ─────────────────────────────────────────────────────────

/**
 * Simulates matching for checked-in participants via the event-matching EF.
 * The EF handles all business logic: group splitting, pair creation, idempotency.
 *
 * EF is the ONLY path — direct DB vote insert fallback has been removed.
 * Fix #1281: direct DB fallback (match_votes insert, match_rules insert) removed.
 * supabaseUrl and serviceRoleKey are required; missing credentials cause an error.
 */
export async function simMatch(
  supabase: SupabaseClient,
  eventIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  supabaseUrl?: string,
  serviceRoleKey?: string,
): Promise<{ matchPairs: Array<{ userId1: string; userId2: string; eventId: string }>; assertions: SimAssertionResult[] }> {
  const matchPairs: Array<{ userId1: string; userId2: string; eventId: string }> = [];
  const assertions: SimAssertionResult[] = [];

  if (eventIds.length === 0) {
    log({ level: "info", phase: "match", step: "skip", message: "No events to process" });
    return { matchPairs, assertions };
  }

  // Fix #1281: EF-only — supabaseUrl/serviceRoleKey are required
  // Fix #1283: strict parameter removed — fail fast always.
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("supabaseUrl and serviceRoleKey are required for event-matching EF");
  }

  // Fix #531: Process events in batches to prevent curl 120s timeout.
  const matchResults = await allSettledInBatches(eventIds, 10, async (eventId) => {
    const efResult = await callEdgeFunction(supabaseUrl, "event-matching", { event_id: eventId }, serviceRoleKey);
    // deno-lint-ignore no-explicit-any
    const efData = efResult.data as any;
    if (efResult.status === 200 && efData?.success) {
      const pairs = (efData.pairs ?? []) as Array<{ user1: string; user2: string }>;
      for (const pair of pairs) {
        matchPairs.push({ userId1: pair.user1, userId2: pair.user2, eventId });
        const pairAssertion = await simAssertMatchPairCreated(supabase, eventId, pair.user1, pair.user2);
        assertions.push(pairAssertion);
      }
      log({ level: "info", phase: "match", step: "ef_match", message: `event-matching EF created ${pairs.length} pairs for event ${eventId}`, data: { eventId, idempotent: efData.idempotent } });
    } else {
      // Fix #1281: EF failure is always an error — no direct DB fallback
      throw new Error(`event-matching EF returned ${efResult.status} for event ${eventId}`);
    }
  });

  for (const r of matchResults) {
    if (r.status === "rejected") {
      log({ level: "error", phase: "match", step: "match_loop", message: `Unexpected error: ${String(r.reason)}` });
    }
  }

  log({
    level: "info",
    phase: "match",
    step: "complete",
    message: `Phase 5 match complete: ${matchPairs.length} pairs created`,
    data: { pairCount: matchPairs.length },
  });

  return { matchPairs, assertions };
}

// ─────────────────────────────────────────────────────────
// simCompleteEvents
// ─────────────────────────────────────────────────────────

/**
 * Marks events as completed by transitioning through the full state machine.
 * // Fix #998: 이벤트 상태 머신 확장 — 순차 전환 (scheduled → active → ongoing → completed)
 * Each step only updates events that are in the expected prior state.
 * UPDATE events SET status='completed' → triggers create_settlement_on_event_completion()
 */
export async function simCompleteEvents(
  supabase: SupabaseClient,
  eventIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
): Promise<{ completedEventIds: string[]; assertions: SimAssertionResult[] }> {
  const completedEventIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  if (eventIds.length === 0) {
    log({ level: "info", phase: "complete_events", step: "skip", message: "No events to complete" });
    return { completedEventIds, assertions };
  }

  // Fix #531: Process events in batches to prevent curl 120s timeout.
  const completeResults = await allSettledInBatches(eventIds, 10, async (eventId) => {
    // Fix #998: 이벤트 상태 머신 확장 — 순차 전환 (scheduled → active → ongoing → completed)
    // Step 1: scheduled → active
    const { error: toActiveErr } = await supabase
      .from("events")
      .update({ status: "active" })
      .eq("id", eventId)
      .eq("status", "scheduled");

    if (toActiveErr) {
      log({ level: "error", phase: "complete_events", step: "transition_to_active", message: `Failed to transition event ${eventId} to active: ${toActiveErr.message}` });
      return;
    }

    // Step 2: active → ongoing
    const { error: toOngoingErr } = await supabase
      .from("events")
      .update({ status: "ongoing" })
      .eq("id", eventId)
      .eq("status", "active");

    if (toOngoingErr) {
      log({ level: "error", phase: "complete_events", step: "transition_to_ongoing", message: `Failed to transition event ${eventId} to ongoing: ${toOngoingErr.message}` });
      return;
    }

    // Step 3: ongoing → completed
    const { error: toCompletedErr } = await supabase
      .from("events")
      .update({ status: "completed" })
      .eq("id", eventId)
      .eq("status", "ongoing");

    if (toCompletedErr) {
      log({ level: "error", phase: "complete_events", step: "transition_to_completed", message: `Failed to transition event ${eventId} to completed: ${toCompletedErr.message}` });
      return;
    }

    completedEventIds.push(eventId);
    log({ level: "info", phase: "complete_events", step: "completed", message: `Event ${eventId} transitioned scheduled → active → ongoing → completed` });
  });

  for (const r of completeResults) {
    if (r.status === "rejected") {
      log({ level: "error", phase: "complete_events", step: "complete_loop", message: `Unexpected error: ${String(r.reason)}` });
    }
  }

  log({
    level: "info",
    phase: "complete_events",
    step: "done",
    message: `Phase 5 complete_events done: ${completedEventIds.length} events completed`,
    data: { completedCount: completedEventIds.length },
  });

  return { completedEventIds, assertions };
}
