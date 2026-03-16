// sim_event.ts — Phase 5: Check-in + Matching + Event Completion

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import {
  simAssertMatchPairCreated,
  simAssertCheckinRatio,
} from "./sim_assertions.ts";

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
): Promise<{ checkedInParticipantIds: string[]; noShowParticipantIds: string[]; assertions: SimAssertionResult[] }> {
  const checkedInParticipantIds: string[] = [];
  const noShowParticipantIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  if (eventIds.length === 0) {
    log({ level: "info", phase: "checkin", step: "skip", message: "No events to process" });
    return { checkedInParticipantIds, noShowParticipantIds, assertions };
  }

  for (const eventId of eventIds) {
    try {
      // Query participants with ticket_issued or checked_in status
      const { data: participants, error: fetchErr } = await supabase
        .from("event_participants")
        .select("id, user_id, status")
        .eq("event_id", eventId);

      if (fetchErr) {
        log({ level: "error", phase: "checkin", step: "fetch_participants", message: `Failed to fetch participants for event ${eventId}: ${fetchErr.message}` });
        continue;
      }

      const rows = (participants ?? []) as Array<{ id: string; user_id: string; status: string }>;
      const eligible = rows.filter((p) => p.status === "ticket_issued" || p.status === "checked_in");

      if (eligible.length === 0) {
        log({ level: "info", phase: "checkin", step: "no_participants", message: `No eligible participants for event ${eventId}` });
        continue;
      }

      const splitIndex = Math.floor(eligible.length * checkinRate);

      for (let i = 0; i < eligible.length; i++) {
        const participant = eligible[i];
        const newStatus = i < splitIndex ? "checked_in" : "no_show";

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
    } catch (e) {
      log({ level: "error", phase: "checkin", step: "checkin_loop", message: `Unexpected error for event ${eventId}: ${String(e)}` });
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
): Promise<{ matchPairs: Array<{ userId1: string; userId2: string; eventId: string }>; assertions: SimAssertionResult[] }> {
  const matchPairs: Array<{ userId1: string; userId2: string; eventId: string }> = [];
  const assertions: SimAssertionResult[] = [];

  if (eventIds.length === 0) {
    log({ level: "info", phase: "match", step: "skip", message: "No events to process" });
    return { matchPairs, assertions };
  }

  for (const eventId of eventIds) {
    try {
      // Query entry_groups for this event
      const { data: groupsData, error: groupsErr } = await supabase
        .from("entry_groups")
        .select("id, gender")
        .eq("event_id", eventId);

      if (groupsErr) {
        log({ level: "error", phase: "match", step: "fetch_groups", message: `Failed to fetch entry_groups for event ${eventId}: ${groupsErr.message}` });
        continue;
      }

      const groups = (groupsData ?? []) as Array<{ id: string; gender: string }>;

      if (groups.length < 2) {
        log({ level: "warn", phase: "match", step: "insufficient_groups", message: `Event ${eventId} has fewer than 2 entry_groups, skipping match` });
        continue;
      }

      // Ensure match_rules exist
      const { data: existingRules, error: rulesErr } = await supabase
        .from("match_rules")
        .select("id")
        .eq("event_id", eventId);

      if (rulesErr) {
        log({ level: "error", phase: "match", step: "fetch_rules", message: `Failed to fetch match_rules for event ${eventId}: ${rulesErr.message}` });
        continue;
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
        continue;
      }

      const participants = (participantsData ?? []) as Array<{ id: string; user_id: string; entry_group_id: string }>;

      if (participants.length < 2) {
        log({ level: "warn", phase: "match", step: "insufficient_participants", message: `Event ${eventId} has fewer than 2 checked_in participants, skipping` });
        continue;
      }

      // Split participants by group
      const groupAId = groups[0].id;
      const groupBId = groups[1].id;
      const groupAParticipants = participants.filter((p) => p.entry_group_id === groupAId);
      const groupBParticipants = participants.filter((p) => p.entry_group_id === groupBId);

      if (groupAParticipants.length === 0 || groupBParticipants.length === 0) {
        log({ level: "warn", phase: "match", step: "empty_group", message: `Event ${eventId}: one group has no checked_in participants` });
        continue;
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
          // Rollback: A→B was already inserted — delete it to avoid half-applied state
          await supabase.from("match_votes")
            .delete()
            .eq("event_id", eventId)
            .eq("voter_id", userA)
            .eq("candidate_id", userB);
          log({
            level: "error", phase: "match", step: "insert_vote",
            message: `Vote B→A failed, rolled back A→B for pair (${userA}, ${userB}): ${voteBErr.message}`,
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
    } catch (e) {
      log({ level: "error", phase: "match", step: "match_loop", message: `Unexpected error for event ${eventId}: ${String(e)}` });
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
 * Marks events as completed.
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

  for (const eventId of eventIds) {
    try {
      const { error: updErr } = await supabase
        .from("events")
        .update({ status: "completed" })
        .eq("id", eventId);

      if (updErr) {
        log({ level: "error", phase: "complete_events", step: "update_event", message: `Failed to complete event ${eventId}: ${updErr.message}` });
        continue;
      }

      completedEventIds.push(eventId);
      log({ level: "info", phase: "complete_events", step: "completed", message: `Event ${eventId} marked as completed` });
    } catch (e) {
      log({ level: "error", phase: "complete_events", step: "complete_loop", message: `Unexpected error for event ${eventId}: ${String(e)}` });
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
