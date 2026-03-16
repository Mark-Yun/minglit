import { assertEquals } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simCheckin, simMatch, simCompleteEvents } from "./sim_event.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};

// ─────────────────────────────────────────────────────────
// simCheckin tests
// ─────────────────────────────────────────────────────────

Deno.test("simCheckin - 70% checked_in, 30% no_show", async () => {
  const participantStatuses: Record<string, string> = {};

  const participants = [
    { id: "p-1", user_id: "u-1", status: "ticket_issued" },
    { id: "p-2", user_id: "u-2", status: "ticket_issued" },
    { id: "p-3", user_id: "u-3", status: "ticket_issued" },
    { id: "p-4", user_id: "u-4", status: "ticket_issued" },
    { id: "p-5", user_id: "u-5", status: "ticket_issued" },
    { id: "p-6", user_id: "u-6", status: "ticket_issued" },
    { id: "p-7", user_id: "u-7", status: "ticket_issued" },
    { id: "p-8", user_id: "u-8", status: "ticket_issued" },
    { id: "p-9", user_id: "u-9", status: "ticket_issued" },
    { id: "p-10", user_id: "u-10", status: "ticket_issued" },
  ];

  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: ({ filters }) => {
          if (filters["event_id"]) {
            return {
              data: participants.map((p) => ({
                ...p,
                status: participantStatuses[p.id] ?? p.status,
              })),
              error: null,
            };
          }
          const id = filters["id"] as string;
          const p = participants.find((x) => x.id === id);
          if (!p) return { data: null, error: null };
          return {
            data: { ...p, status: participantStatuses[p.id] ?? p.status },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const id = filters["id"] as string;
          const v = values as { status: string };
          participantStatuses[id] = v.status;
          return { data: null, error: null };
        },
      },
    },
  });

  const result = await simCheckin(
    mock as unknown as SupabaseClient,
    ["event-1"],
    noop,
    0.7,
  );

  assertEquals(result.checkedInParticipantIds.length, 7);
  assertEquals(result.noShowParticipantIds.length, 3);
  assertEquals(result.assertions.length, 1);
  assertEquals(result.assertions[0].passed, true);
});

Deno.test("simCheckin - empty participants returns empty", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: [], error: null }),
      },
    },
  });

  const result = await simCheckin(
    mock as unknown as SupabaseClient,
    ["event-empty"],
    noop,
    0.7,
  );

  assertEquals(result.checkedInParticipantIds, []);
  assertEquals(result.noShowParticipantIds, []);
  assertEquals(result.assertions, []);
});

// ─────────────────────────────────────────────────────────
// simMatch tests
// ─────────────────────────────────────────────────────────

Deno.test("simMatch - bidirectional votes → match pair created (assert passes)", async () => {
  const insertedVotes: Array<{ voter_id: string; candidate_id: string }> = [];

  const mock = createMockSupabaseClient({
    tables: {
      entry_groups: {
        select: () => ({
          data: [
            { id: "group-a", gender: "male" },
            { id: "group-b", gender: "female" },
          ],
          error: null,
        }),
      },
      match_rules: {
        select: () => ({ data: [{ id: "rule-1" }], error: null }),
        insert: () => ({ data: null, error: null }),
      },
      event_participants: {
        select: ({ filters }) => {
          if (filters["status"] === "checked_in") {
            return {
              data: [
                { id: "ep-1", user_id: "user-a", entry_group_id: "group-a" },
                { id: "ep-2", user_id: "user-b", entry_group_id: "group-b" },
              ],
              error: null,
            };
          }
          return { data: [], error: null };
        },
      },
      match_votes: {
        insert: ({ values }) => {
          const v = values as { voter_id: string; candidate_id: string };
          insertedVotes.push({ voter_id: v.voter_id, candidate_id: v.candidate_id });
          return { data: null, error: null };
        },
      },
      match_pairs: {
        select: ({ filters }) => {
          const lowerUserId = filters["user_lower_id"] as string;
          const higherUserId = filters["user_higher_id"] as string;
          const hasAtoB = insertedVotes.some((v) => v.voter_id === "user-a" && v.candidate_id === "user-b");
          const hasBtoA = insertedVotes.some((v) => v.voter_id === "user-b" && v.candidate_id === "user-a");
          if (hasAtoB && hasBtoA && lowerUserId && higherUserId) {
            return { data: { id: "pair-1" }, error: null };
          }
          return { data: null, error: null };
        },
      },
    },
  });

  const result = await simMatch(
    mock as unknown as SupabaseClient,
    ["event-1"],
    noop,
  );

  assertEquals(result.matchPairs.length, 1);
  assertEquals(result.matchPairs[0].userId1, "user-a");
  assertEquals(result.matchPairs[0].userId2, "user-b");
  assertEquals(result.assertions.length, 1);
  assertEquals(result.assertions[0].passed, true);
});

Deno.test("simMatch - unidirectional vote → no match pair (negative test)", async () => {
  const insertedVotes: Array<{ voter_id: string; candidate_id: string }> = [];
  let voteCount = 0;

  const mock = createMockSupabaseClient({
    tables: {
      entry_groups: {
        select: () => ({
          data: [
            { id: "group-a", gender: "male" },
            { id: "group-b", gender: "female" },
          ],
          error: null,
        }),
      },
      match_rules: {
        select: () => ({ data: [{ id: "rule-1" }], error: null }),
        insert: () => ({ data: null, error: null }),
      },
      event_participants: {
        select: ({ filters }) => {
          if (filters["status"] === "checked_in") {
            return {
              data: [
                { id: "ep-1", user_id: "user-a", entry_group_id: "group-a" },
                { id: "ep-2", user_id: "user-b", entry_group_id: "group-b" },
              ],
              error: null,
            };
          }
          return { data: [], error: null };
        },
      },
      match_votes: {
        insert: ({ values }) => {
          const v = values as { voter_id: string; candidate_id: string };
          voteCount++;
          if (voteCount === 2) {
            return { data: null, error: { message: "Simulated failure for reverse vote" } };
          }
          insertedVotes.push({ voter_id: v.voter_id, candidate_id: v.candidate_id });
          return { data: null, error: null };
        },
      },
      match_pairs: {
        select: () => {
          const hasAtoB = insertedVotes.some((v) => v.voter_id === "user-a" && v.candidate_id === "user-b");
          const hasBtoA = insertedVotes.some((v) => v.voter_id === "user-b" && v.candidate_id === "user-a");
          if (hasAtoB && hasBtoA) {
            return { data: { id: "pair-1" }, error: null };
          }
          return { data: null, error: null };
        },
      },
    },
  });

  const result = await simMatch(
    mock as unknown as SupabaseClient,
    ["event-1"],
    noop,
  );

  assertEquals(result.matchPairs.length, 0);
  assertEquals(result.assertions.length, 0);
});

// ─────────────────────────────────────────────────────────
// simCompleteEvents tests
// ─────────────────────────────────────────────────────────

Deno.test("simCompleteEvents - events marked completed", async () => {
  const eventStatuses: Record<string, string> = {};

  const mock = createMockSupabaseClient({
    tables: {
      events: {
        update: ({ values, filters }) => {
          const eventId = filters["id"] as string;
          const v = values as { status: string };
          eventStatuses[eventId] = v.status;
          return { data: null, error: null };
        },
      },
    },
  });

  const result = await simCompleteEvents(
    mock as unknown as SupabaseClient,
    ["event-1", "event-2", "event-3"],
    noop,
  );

  assertEquals(result.completedEventIds.length, 3);
  assertEquals(result.completedEventIds, ["event-1", "event-2", "event-3"]);
  assertEquals(eventStatuses["event-1"], "completed");
  assertEquals(eventStatuses["event-2"], "completed");
  assertEquals(eventStatuses["event-3"], "completed");
  assertEquals(result.assertions, []);
});

Deno.test("simCompleteEvents - empty list returns empty result", async () => {
  const mock = createMockSupabaseClient({});

  const result = await simCompleteEvents(
    mock as unknown as SupabaseClient,
    [],
    noop,
  );

  assertEquals(result.completedEventIds, []);
  assertEquals(result.assertions, []);
});
