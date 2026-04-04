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
 * - checkinRate (default 0.7) fraction → status='checked_in'
 * - remaining fraction → status='no_show'
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

  // Fix #998: event-checkin EF requires status='active' or 'ongoing', but simCheckin is called
  // before simCompleteEvents (which drives scheduled→active→ongoing→completed). Pre-activate
  // all scheduled events here so the EF status gate passes — mirrors real-world cron activation.
  const { error: preActivateErr } = await supabase
    .from("events")
    .update({ status: "active" })
    .eq("status", "scheduled")
    .in("id", eventIds);

  if (preActivateErr) {
    log({ level: "warn", phase: "checkin", step: "pre_activate", message: `Failed to pre-activate scheduled events: ${preActivateErr.message}` });
  } else {
    log({ level: "info", phase: "checkin", step: "pre_activate", message: `Pre-activated scheduled events to active for EF check-in (${eventIds.length} event IDs processed)` });
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

      if (newStatus === "checked_in" && supabaseUrl && anonKey) {
        // Attempt to use event-checkin EF with user token
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
              log({ level: "warn", phase: "checkin", step: "ef_checkin_failed", message: `event-checkin EF returned ${efResult.status} for participant ${participant.id}, falling back to direct update` });
            }
          } catch (authErr) {
            log({ level: "warn", phase: "checkin", step: "ef_auth_fallback", message: `Auth failed for ${username}, using direct update: ${String(authErr)}` });
          }
        }
      }

      // Fallback: direct DB update (for no_show and when EF call unavailable)
      const { error: updErr } = await supabase
        .from("event_participants")
        .update({ status: newStatus })
        .eq("id", participant.id);

      if (updErr) {
        log({ level: "error", phase: "checkin", step: "update_participant", message: `Failed to update participant ${participant.id}: ${updErr.message}` });
        continue;
      }

      if (newStatus === "checked_in") {
        checkedInParticipantIds.push(participant.id);
      } else {
        noShowParticipantIds.push(participant.id);
      }
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
 * Simulates match voting for checked-in participants.
 * - Queries entry_groups for each event
 * - Ensures match_rules exist (inserts basic rules if missing)
 * - Inserts match_votes: each checked-in participant votes for one from opposite group
 * - For a subset: inserts reverse vote too → triggers match_pairs creation
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

  // Fix #531: Process events in batches to prevent curl 120s timeout.
  const matchResults = await allSettledInBatches(eventIds, 10, async (eventId) => {
    // Attempt to use event-matching EF with service_role token (admin operation)
    if (supabaseUrl && serviceRoleKey) {
      try {
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
          return;
        } else {
          log({ level: "warn", phase: "match", step: "ef_match_failed", message: `event-matching EF returned ${efResult.status} for event ${eventId}, falling back to direct vote insert` });
        }
      } catch (efErr) {
        log({ level: "warn", phase: "match", step: "ef_match_error", message: `event-matching EF error for event ${eventId}: ${String(efErr)}, falling back to direct vote insert` });
      }
    }

    // Fallback: direct vote insert (used when EF call unavailable or failed)
    // Query entry_groups for this event
    const { data: groupsData, error: groupsErr } = await supabase
      .from("entry_groups")
      .select("id, gender")
      .eq("event_id", eventId);

    if (groupsErr) {
      log({ level: "error", phase: "match", step: "fetch_groups", message: `Failed to fetch entry_groups for event ${eventId}: ${groupsErr.message}` });
      return;
    }

    const groups = (groupsData ?? []) as Array<{ id: string; gender: string }>;

    if (groups.length < 2) {
      log({ level: "warn", phase: "match", step: "insufficient_groups", message: `Event ${eventId} has fewer than 2 entry_groups, skipping match` });
      return;
    }

    // Ensure match_rules exist
    const { data: existingRules, error: rulesErr } = await supabase
      .from("match_rules")
      .select("id")
      .eq("event_id", eventId);

    if (rulesErr) {
      log({ level: "error", phase: "match", step: "fetch_rules", message: `Failed to fetch match_rules for event ${eventId}: ${rulesErr.message}` });
      return;
    }

    const rules = (existingRules ?? []) as Array<{ id: string }>;

    if (rules.length === 0) {
      // Insert basic bidirectional match rules between first two groups
      const groupA = groups[0];
      const groupB = groups[1];

      await supabase.from("match_rules").insert({
        event_id: eventId,
        source_group_id: groupA.id,
        target_group_id: groupB.id,
      });
      await supabase.from("match_rules").insert({
        event_id: eventId,
        source_group_id: groupB.id,
        target_group_id: groupA.id,
      });

      log({ level: "info", phase: "match", step: "insert_rules", message: `Inserted basic match_rules for event ${eventId}` });
    }

    // Get checked_in participants
    const { data: participantsData, error: partErr } = await supabase
      .from("event_participants")
      .select("id, user_id, entry_group_id")
      .eq("event_id", eventId)
      .eq("status", "checked_in");

    if (partErr) {
      log({ level: "error", phase: "match", step: "fetch_checked_in", message: `Failed to fetch checked_in participants for event ${eventId}: ${partErr.message}` });
      return;
    }

    const participants = (participantsData ?? []) as Array<{ id: string; user_id: string; entry_group_id: string }>;

    if (participants.length < 2) {
      log({ level: "warn", phase: "match", step: "insufficient_participants", message: `Event ${eventId} has fewer than 2 checked_in participants, skipping` });
      return;
    }

    // Split participants by group
    const groupAId = groups[0].id;
    const groupBId = groups[1].id;
    const groupAParticipants = participants.filter((p) => p.entry_group_id === groupAId);
    const groupBParticipants = participants.filter((p) => p.entry_group_id === groupBId);

    if (groupAParticipants.length === 0 || groupBParticipants.length === 0) {
      log({ level: "warn", phase: "match", step: "empty_group", message: `Event ${eventId}: one group has no checked_in participants` });
      return;
    }

    // Insert cross-group votes
    // Each participant from group A votes for one from group B (and vice versa)
    const pairsToCreate: Array<{ userA: string; userB: string }> = [];
    const minCount = Math.min(groupAParticipants.length, groupBParticipants.length);

    for (let i = 0; i < minCount; i++) {
      const userA = groupAParticipants[i].user_id;
      const userB = groupBParticipants[i].user_id;
      pairsToCreate.push({ userA, userB });
    }

    for (const { userA, userB } of pairsToCreate) {
      // Insert vote A→B
      const { error: voteAErr } = await supabase.from("match_votes").insert({
        event_id: eventId,
        voter_id: userA,
        candidate_id: userB,
      });
      if (voteAErr) {
        log({ level: "error", phase: "match", step: "insert_vote", message: `Failed to insert vote ${userA}→${userB}: ${voteAErr.message}` });
        continue;
      }

      // Insert reverse vote B→A → triggers match_pairs creation
      const { error: voteBErr } = await supabase.from("match_votes").insert({
        event_id: eventId,
        voter_id: userB,
        candidate_id: userA,
      });
      if (voteBErr) {
        // Fix #531: Do NOT rollback A→B — handle_new_match_vote() trigger may have
        // already created match_pairs, so deleting A→B would leave inconsistent state.
        log({
          level: "warn", phase: "match", step: "insert_vote",
          message: `Vote B→A failed, keeping A→B as-is for pair (${userA}, ${userB}): ${voteBErr.message}`,
        });
        continue;
      }

      // Assert match pair was created by trigger
      const pairAssertion = await simAssertMatchPairCreated(supabase, eventId, userA, userB);
      assertions.push(pairAssertion);

      if (pairAssertion.passed) {
        matchPairs.push({ userId1: userA, userId2: userB, eventId });
        log({ level: "info", phase: "match", step: "pair_created", message: `Match pair created: ${userA} ↔ ${userB} in event ${eventId}` });
      } else {
        log({ level: "warn", phase: "match", step: "pair_missing", message: `Match pair assertion failed: ${pairAssertion.details}` });
      }
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
