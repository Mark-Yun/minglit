import { assertEquals, assertRejects } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simCheckin, simMatch, simCompleteEvents } from "./sim_event.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};

// Intercept module-level EF + auth calls via mock fetch.
// callEdgeFunction and getSimUserToken both use globalThis.fetch internally.
function withMockFetch<T>(
  handler: (url: string, init: RequestInit) => Response,
  fn: () => Promise<T>,
): Promise<T> {
  const original = globalThis.fetch;
  globalThis.fetch = (url: string | URL | Request, init?: RequestInit) =>
    Promise.resolve(handler(url.toString(), init ?? {}));
  return fn().finally(() => {
    globalThis.fetch = original;
  });
}

// Returns a mock fetch handler that:
// - Responds to Supabase auth signIn with a fake JWT
// - Responds to event-checkin EF with success or failure based on opts.efStatus
function makeCheckinFetchHandler(opts: { efStatus?: number } = {}): (url: string, init: RequestInit) => Response {
  const efStatus = opts.efStatus ?? 200;
  return (url: string, _init: RequestInit) => {
    if (url.includes("auth/v1/token")) {
      // getSimUserToken calls supabase.auth.signInWithPassword → POST /auth/v1/token
      // supabase-js requires expires_in and refresh_token to build a valid session
      return new Response(
        JSON.stringify({
          access_token: "mock-user-token",
          token_type: "bearer",
          expires_in: 3600,
          refresh_token: "mock-refresh",
          user: { id: "user-id" },
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    if (url.includes("functions/v1/event-checkin")) {
      if (efStatus === 200) {
        return new Response(
          JSON.stringify({ success: true, participant_id: "mock-pid", status: "checked_in" }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      return new Response(
        JSON.stringify({ error: "Simulated EF failure" }),
        { status: efStatus, headers: { "Content-Type": "application/json" } },
      );
    }
    // Unexpected URL — return 500 to surface test issues
    return new Response(JSON.stringify({ error: "unexpected url" }), { status: 500 });
  };
}

// Returns a mock fetch handler for event-matching EF
function makeMatchFetchHandler(opts: { efStatus?: number; pairs?: Array<{ user1: string; user2: string }> } = {}): (url: string, init: RequestInit) => Response {
  const efStatus = opts.efStatus ?? 200;
  const pairs = opts.pairs ?? [{ user1: "user-a", user2: "user-b" }];
  return (url: string, _init: RequestInit) => {
    if (url.includes("functions/v1/event-matching")) {
      if (efStatus === 200) {
        return new Response(
          JSON.stringify({ success: true, match_count: pairs.length, pairs, idempotent: false }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      return new Response(
        JSON.stringify({ error: "Simulated EF failure" }),
        { status: efStatus, headers: { "Content-Type": "application/json" } },
      );
    }
    return new Response(JSON.stringify({ error: "unexpected url" }), { status: 500 });
  };
}

// ─────────────────────────────────────────────────────────
// simCheckin tests
// ─────────────────────────────────────────────────────────

// Fix #1292: sanitizer 복원 — autoRefreshToken: false로 supabase-js interval 누수 해결
Deno.test({
  name: "simCheckin - 70% checked_in via EF, 30% no_show via direct DB",
  fn: async () => {
    const noShowUpdated: string[] = [];
    // Track statuses for both EF (via fetch mock side-effect) and direct DB (via update mock)
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
        events: {
          update: () => ({ data: null, error: null }),
        },
        event_participants: {
          select: ({ filters }) => {
            // simAssertCheckinRatio queries by status=checked_in to count checked-in participants.
            // Since EF does the actual DB update in production (not in test mock), we count
            // participantStatuses entries updated by both EF side-effect and direct DB update.
            if (filters["event_id"] && filters["status"] === "checked_in") {
              const checkedInCount = Object.values(participantStatuses).filter((s) => s === "checked_in").length;
              return { data: new Array(checkedInCount).fill({ id: "x", status: "checked_in" }), error: null };
            }
            if (filters["event_id"]) {
              return {
                data: participants.map((p) => ({
                  ...p,
                  status: participantStatuses[p.id] ?? p.status,
                })),
                error: null,
              };
            }
            return { data: [], error: null };
          },
          update: ({ values, filters }) => {
            const id = filters["id"] as string;
            const v = values as { status: string };
            if (v.status === "no_show") {
              noShowUpdated.push(id);
            }
            participantStatuses[id] = v.status;
            return { data: null, error: null };
          },
        },
        user_profiles: {
          select: ({ filters }) => {
            const userId = filters["id"] as string;
            const idx = participants.findIndex((p) => p.user_id === userId);
            if (idx >= 0) {
              return { data: { username: `user_${idx + 1}` }, error: null };
            }
            return { data: null, error: null };
          },
        },
      },
    });

    // Custom fetch handler that also tracks EF checkins in participantStatuses,
    // mirroring what the real EF would do to the DB.
    const fetchHandler = (url: string, init: RequestInit): Response => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({
            access_token: "mock-user-token",
            token_type: "bearer",
            expires_in: 3600,
            refresh_token: "mock-refresh",
            user: { id: "user-id" },
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      if (url.includes("functions/v1/event-checkin")) {
        // Parse request body to get participant_id and simulate DB update
        const body = JSON.parse((init.body as string) ?? "{}") as { participant_id?: string };
        const pid = body.participant_id ?? "unknown";
        participantStatuses[pid] = "checked_in"; // mirrors EF's DB update
        return new Response(
          JSON.stringify({ success: true, participant_id: pid, status: "checked_in" }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      }
      return new Response(JSON.stringify({ error: "unexpected url" }), { status: 500 });
    };

    const result = await withMockFetch(
      fetchHandler,
      () => simCheckin(
        mock as unknown as SupabaseClient,
        ["event-1"],
        noop,
        0.7,
        "https://example.supabase.co",
        "anon-key",
      ),
    );

    // 7 participants checked in via EF, 3 no_show via direct DB
    assertEquals(result.checkedInParticipantIds.length, 7);
    assertEquals(result.noShowParticipantIds.length, 3);
    assertEquals(noShowUpdated.length, 3);
    assertEquals(result.assertions.length, 1);
    assertEquals(result.assertions[0].passed, true);
  },
});

Deno.test({ name: "simCheckin - empty participants returns empty", fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      events: {
        update: () => ({ data: null, error: null }),
      },
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
    "https://example.supabase.co",
    "anon-key",
  );

  assertEquals(result.checkedInParticipantIds, []);
  assertEquals(result.noShowParticipantIds, []);
  assertEquals(result.assertions, []);
}});

Deno.test({
  name: "simCheckin - EF failure is logged as error (not silently skipped)",
  fn: async () => {
    const participants = [
      { id: "p-1", user_id: "u-1", status: "ticket_issued" },
      { id: "p-2", user_id: "u-2", status: "ticket_issued" },
      { id: "p-3", user_id: "u-3", status: "ticket_issued" },
    ];

    const mock = createMockSupabaseClient({
      tables: {
        events: {
          update: () => ({ data: null, error: null }),
        },
        event_participants: {
          select: ({ filters }) => {
            if (filters["event_id"]) {
              return { data: participants, error: null };
            }
            return { data: [], error: null };
          },
          update: () => ({ data: null, error: null }),
        },
        user_profiles: {
          select: () => ({ data: { username: "user_1" }, error: null }),
        },
      },
    });

    // EF returns 500 — this causes an error to be thrown in the participant loop,
    // which propagates to allSettledInBatches and is logged as error.
    const logs: string[] = [];
    const collectLog = (entry: { level: string; message: string }) => {
      logs.push(`${entry.level}: ${entry.message}`);
    };

    await withMockFetch(
      makeCheckinFetchHandler({ efStatus: 500 }),
      () => simCheckin(
        mock as unknown as SupabaseClient,
        ["event-1"],
        collectLog,
        0.7,
        "https://example.supabase.co",
        "anon-key",
      ),
    );

    // The error should have been caught and logged by the batch handler
    const errorLogs = logs.filter((l) => l.startsWith("error:"));
    assertEquals(errorLogs.length >= 1, true);
  },
});

Deno.test("simCheckin - no credentials throws immediately", async () => {
  const mock = createMockSupabaseClient({});

  await assertRejects(
    () => simCheckin(
      mock as unknown as SupabaseClient,
      ["event-1"],
      noop,
      0.7,
    ),
    Error,
    "supabaseUrl and anonKey are required",
  );
});

// ─────────────────────────────────────────────────────────
// simMatch tests
// ─────────────────────────────────────────────────────────

Deno.test("simMatch - successful matching via EF", async () => {
  const pairs = [{ user1: "user-a", user2: "user-b" }];

  const mock = createMockSupabaseClient({
    tables: {
      match_pairs: {
        select: ({ filters }) => {
          // simAssertMatchPairCreated queries by user_lower_id + user_higher_id
          const lowerUserId = filters["user_lower_id"] as string;
          const higherUserId = filters["user_higher_id"] as string;
          if (lowerUserId && higherUserId) {
            return { data: { id: "pair-1" }, error: null };
          }
          return { data: null, error: null };
        },
      },
    },
  });

  const result = await withMockFetch(
    makeMatchFetchHandler({ pairs }),
    () => simMatch(
      mock as unknown as SupabaseClient,
      ["event-1"],
      noop,
      "https://example.supabase.co",
      "service-role-key",
    ),
  );

  assertEquals(result.matchPairs.length, 1);
  assertEquals(result.matchPairs[0].userId1, "user-a");
  assertEquals(result.matchPairs[0].userId2, "user-b");
  assertEquals(result.matchPairs[0].eventId, "event-1");
  assertEquals(result.assertions.length, 1);
  assertEquals(result.assertions[0].passed, true);
});

Deno.test("simMatch - EF failure is logged as error (not silently skipped)", async () => {
  const mock = createMockSupabaseClient({});

  const logs: string[] = [];
  const collectLog = (entry: { level: string; message: string }) => {
    logs.push(`${entry.level}: ${entry.message}`);
  };

  await withMockFetch(
    makeMatchFetchHandler({ efStatus: 500 }),
    () => simMatch(
      mock as unknown as SupabaseClient,
      ["event-1"],
      collectLog,
      "https://example.supabase.co",
      "service-role-key",
    ),
  );

  // Error should be caught by allSettledInBatches and logged
  const errorLogs = logs.filter((l) => l.startsWith("error:"));
  assertEquals(errorLogs.length >= 1, true);
});

Deno.test("simMatch - empty event list returns empty result", async () => {
  const mock = createMockSupabaseClient({});

  const result = await simMatch(
    mock as unknown as SupabaseClient,
    [],
    noop,
    "https://example.supabase.co",
    "service-role-key",
  );

  assertEquals(result.matchPairs, []);
  assertEquals(result.assertions, []);
});

Deno.test("simMatch - no credentials throws immediately", async () => {
  const mock = createMockSupabaseClient({});

  await assertRejects(
    () => simMatch(
      mock as unknown as SupabaseClient,
      ["event-1"],
      noop,
    ),
    Error,
    "supabaseUrl and serviceRoleKey are required for event-matching EF",
  );
});

Deno.test("simMatch - multiple events, multiple pairs via EF", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      match_pairs: {
        select: ({ filters }) => {
          if (filters["user_lower_id"] && filters["user_higher_id"]) {
            return { data: { id: "pair-1" }, error: null };
          }
          return { data: null, error: null };
        },
      },
    },
  });

  const result = await withMockFetch(
    makeMatchFetchHandler({ pairs: [{ user1: "user-a", user2: "user-b" }] }),
    () => simMatch(
      mock as unknown as SupabaseClient,
      ["event-1", "event-2"],
      noop,
      "https://example.supabase.co",
      "service-role-key",
    ),
  );

  // 1 pair per event × 2 events
  assertEquals(result.matchPairs.length, 2);
  assertEquals(result.assertions.length, 2);
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
