import { assertEquals, assertRejects, assertStringIncludes } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simCreateParties, simDiscoverAndApply } from "./sim_create.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimConfig } from "./sim_types.ts";

const DEFAULT_CONFIG: SimConfig = {
  error_rate: 0.2,
  refund_rate: 0.2,
  party_count: 2,
  events_per_party: 2,
  max_apps_per_user: 3,
  user_batch_size: 10,
  checkin_rate: 0.7,
  no_show_rate: 0.3,
  strict: false,
};

const noop = () => {};

Deno.test("simCreateParties - creates parties with [E2E] prefix", async () => {
  const createdParties: unknown[] = [];
  const createdEvents: unknown[] = [];
  const createdGroups: unknown[] = [];
  const createdTickets: unknown[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }, { id: "partner-2" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      parties: {
        insert: ({ values }: { values: unknown }) => {
          createdParties.push(values);
          return { data: { id: "party-1" }, error: null };
        },
      },
      events: {
        insert: ({ values }) => {
          createdEvents.push(values as { start_time: string });
          return { data: { id: `event-${createdEvents.length}` }, error: null };
        },
      },
      entry_groups: {
        insert: ({ values }: { values: unknown }) => {
          createdGroups.push(values);
          return { data: { id: `group-${createdGroups.length}` }, error: null };
        },
      },
      tickets: {
        insert: ({ values }: { values: unknown }) => {
          createdTickets.push(values);
          return { data: null, error: null };
        },
      },
    },
  });

  await simCreateParties(mock as unknown as SupabaseClient, DEFAULT_CONFIG, noop);

  assertEquals(createdParties.length, 2);
  const party = createdParties[0] as { title: string };
  assertStringIncludes(party.title, "[E2E]");
  assertEquals(createdEvents.length, 4);
});

Deno.test("simCreateParties - creates 4 distinct start_time zones", async () => {
  const createdEvents: { start_time: string }[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      parties: { insert: () => ({ data: { id: "party-1" }, error: null }) },
      events: {
        insert: ({ values }) => {
          const v = values as { start_time: string };
          createdEvents.push(v);
          return { data: { id: `event-${createdEvents.length}` }, error: null };
        },
      },
      entry_groups: { insert: () => ({ data: { id: "group-1" }, error: null }) },
      tickets: { insert: () => ({ data: null, error: null }) },
    },
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 4 };
  await simCreateParties(mock as unknown as SupabaseClient, config, noop);

  assertEquals(createdEvents.length, 4);
  const now = Date.now();
  const times = createdEvents.map((e) => new Date(e.start_time).getTime());

  const plusTwoDays = now + 2 * 24 * 60 * 60 * 1000;
  const plusFiveDays = now + 5 * 24 * 60 * 60 * 1000;
  const plusThirtyDays = now + 30 * 24 * 60 * 60 * 1000;
  const plusTwelveHours = now + 12 * 60 * 60 * 1000;

  const allAboveTwoHours = times.every((t) => t - now > 2 * 60 * 60 * 1000);
  assertEquals(allAboveTwoHours, true);

  const hasManyDaysApart = times.some((t) => t > plusThirtyDays - 60000);
  assertEquals(hasManyDaysApart, true);
  const hasFiveDays = times.some((t) => t > plusFiveDays - 60000 && t < plusFiveDays + 60000);
  assertEquals(hasFiveDays, true);
  const hasTwoDays = times.some((t) => t > plusTwoDays - 60000 && t < plusTwoDays + 60000);
  assertEquals(hasTwoDays, true);
  const hasTwelveHours = times.some((t) => t > plusTwelveHours - 60000 && t < plusTwelveHours + 60000);
  assertEquals(hasTwelveHours, true);
});

// ── EF path tests ────────────────────────────────────────────────────────────

// Intercept module-level EF calls via mock fetch. We replace globalThis.fetch
// for the duration of the test to simulate EF responses without a real server.

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

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simCreateParties - uses EF path when supabaseUrl/anonKey provided and EF succeeds",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const efCalls: { url: string; body: unknown }[] = [];
  const directInserts: string[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [{ id: "tmpl-1", name: "일반" }], error: null }) },
      // direct DB inserts should NOT be called on EF success path
      parties: {
        insert: ({ values }: { values: unknown }) => {
          directInserts.push("party");
          return { data: { id: "direct-party" }, error: null };
        },
      },
      events: {
        insert: ({ values }: { values: unknown }) => {
          directInserts.push("event");
          return { data: { id: "direct-event" }, error: null };
        },
      },
      entry_groups: { insert: () => ({ data: { id: "grp-1" }, error: null }) },
      tickets: { insert: () => ({ data: null, error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 1 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
  await withMockFetch((url, init) => {
    const body = JSON.parse((init.body as string) ?? "{}");
    efCalls.push({ url, body });

    if (url.includes("auth/v1/token")) {
      // Simulate successful partner sign-in
      return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
    }
    if (url.includes("partner-manage-party")) {
      return new Response(JSON.stringify({ success: true, party_id: "ef-party-1" }), { status: 200 });
    }
    if (url.includes("partner-manage-event")) {
      return new Response(JSON.stringify({ success: true, event_id: "ef-event-1" }), { status: 200 });
    }
    return new Response(JSON.stringify({}), { status: 404 });
  }, async () => {
    const result = await simCreateParties(
      mock as unknown as SupabaseClient,
      config,
      noop,
      "https://mock.supabase.co",
      "anon-key",
    );

    assertEquals(result.partyIds, ["ef-party-1"]);
    assertEquals(result.eventIds, ["ef-event-1"]);
    // Direct DB inserts should not have been called for party/event
    assertEquals(directInserts.filter((d) => d === "party").length, 0);
    assertEquals(directInserts.filter((d) => d === "event").length, 0);
    // EF calls were made for party and event
    assertEquals(efCalls.some((c) => c.url.includes("partner-manage-party")), true);
    assertEquals(efCalls.some((c) => c.url.includes("partner-manage-event")), true);
  });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simCreateParties - falls back to direct DB when EF fails and strict=false",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const directPartyInserts: unknown[] = [];
  const directEventInserts: unknown[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [], error: null }) },
      parties: {
        insert: ({ values }: { values: unknown }) => {
          directPartyInserts.push(values);
          return { data: { id: "db-party-1" }, error: null };
        },
      },
      events: {
        insert: ({ values }: { values: unknown }) => {
          directEventInserts.push(values);
          return { data: { id: "db-event-1" }, error: null };
        },
      },
      entry_groups: { insert: () => ({ data: { id: "grp-1" }, error: null }) },
      tickets: { insert: () => ({ data: null, error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 1 };
  const warnings: string[] = [];
  const warnLog = (entry: { level: string; message: string }) => {
    if (entry.level === "warn") warnings.push(entry.message);
  };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
      }
      // EF returns 500 to simulate failure
      return new Response(JSON.stringify({ error: "internal" }), { status: 500 });
    }, async () => {
      const result = await simCreateParties(
        mock as unknown as SupabaseClient,
        config,
        warnLog as Parameters<typeof simCreateParties>[2],
        "https://mock.supabase.co",
        "anon-key",
        false, // strict=false
      );

      // Should have fallen back to direct DB for both party and event
      assertEquals(directPartyInserts.length, 1);
      assertEquals(directEventInserts.length, 1);
      assertEquals(result.partyIds.length, 1);
      assertEquals(result.eventIds.length, 1);
      // Warning was emitted for EF failure
      assertEquals(warnings.some((w) => w.includes("falling back to direct DB")), true);
    });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simCreateParties - throws when EF fails and strict=true",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [], error: null }) },
      parties: { insert: () => ({ data: { id: "db-party-1" }, error: null }) },
      events: { insert: () => ({ data: { id: "db-event-1" }, error: null }) },
      entry_groups: { insert: () => ({ data: { id: "grp-1" }, error: null }) },
      tickets: { insert: () => ({ data: null, error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 1 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
  await withMockFetch((url) => {
    if (url.includes("auth/v1/token")) {
      return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
    }
    return new Response(JSON.stringify({ error: "internal" }), { status: 500 });
  }, async () => {
    await assertRejects(
      () => simCreateParties(
        mock as unknown as SupabaseClient,
        config,
        noop,
        "https://mock.supabase.co",
        "anon-key",
        true, // strict=true → should throw
      ),
      Error,
      "EF partner-manage-party returned status=500",
    );
  });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

Deno.test("simCreateParties - direct DB path when supabaseUrl/anonKey not provided", async () => {
  const createdParties: unknown[] = [];
  const createdEvents: unknown[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      parties: {
        insert: ({ values }: { values: unknown }) => {
          createdParties.push(values);
          return { data: { id: "db-party-1" }, error: null };
        },
      },
      events: {
        insert: ({ values }: { values: unknown }) => {
          createdEvents.push(values);
          return { data: { id: "db-event-1" }, error: null };
        },
      },
      entry_groups: { insert: () => ({ data: { id: "grp-1" }, error: null }) },
      tickets: { insert: () => ({ data: null, error: null }) },
    },
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 2 };
  // No supabaseUrl/anonKey → always direct DB
  const result = await simCreateParties(mock as unknown as SupabaseClient, config, noop);

  assertEquals(result.partyIds.length, 1);
  assertEquals(result.eventIds.length, 2);
  assertEquals(createdParties.length, 1);
  assertEquals(createdEvents.length, 2);
});

// ── simDiscoverAndApply — user-centric loop tests (Fix #1323) ────────────────

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - basic user-centric flow: users discover and apply via own feed",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  let appCounter = 0;
  const feedCallUserTokens: string[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [
            { id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" },
            { id: "user-2", gender: "female", birth_date: "1999-01-01", username: "user2" },
          ],
          error: null,
        }),
      },
    },
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url, init) => {
      if (url.includes("auth/v1/token")) {
        const body = JSON.parse((init.body as string) ?? "{}");
        const token = `token-for-${body.email ?? "unknown"}`;
        return new Response(
          JSON.stringify({ access_token: token, token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        // Record which user token called the feed
        const authHeader = (init.headers as Record<string, string>)["Authorization"] ?? "";
        feedCallUserTokens.push(authHeader);
        // Each user's feed returns one non-E2E event with a ticket
        appCounter;
        return new Response(
          JSON.stringify({
            events: [
              { id: "feed-event-1", title: "소셜 밍글", party: { title: "일반 파티" }, tickets: [{ id: "ticket-1", price: 20000 }] },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        appCounter++;
        return new Response(JSON.stringify({ type: "paid", application_id: `app-${appCounter}` }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        DEFAULT_CONFIG,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    // Both users fetched their own feed
    assertEquals(feedCallUserTokens.length, 2);
    // Both users applied
    assertEquals(result.applicationIds.length, 2);
    assertEquals(result.paidApplicationIds.length, 2);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - max_apps_per_user limit is respected",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  let appCounter = 0;

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [{ id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" }],
          error: null,
        }),
      },
    },
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, max_apps_per_user: 2 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        // Feed returns 5 events — user should only apply to max_apps_per_user=2
        return new Response(
          JSON.stringify({
            events: Array.from({ length: 5 }, (_, i) => ({
              id: `event-${i}`,
              title: `이벤트 ${i}`,
              party: { title: "일반 파티" },
              tickets: [{ id: `ticket-${i}`, price: 20000 }],
            })),
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        appCounter++;
        return new Response(JSON.stringify({ type: "paid", application_id: `app-${appCounter}` }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    // User applied at most max_apps_per_user=2 times despite 5 events in feed
    assertEquals(result.applicationIds.length, 2);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - EF rejection handled gracefully (non-200 response)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const warnings: string[] = [];
  const warnLog = (entry: { level: string; message: string }) => {
    if (entry.level === "warn" || entry.level === "error") warnings.push(entry.message);
  };

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [{ id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" }],
          error: null,
        }),
      },
    },
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        return new Response(
          JSON.stringify({
            events: [
              { id: "event-1", title: "이벤트 1", party: { title: "일반 파티" }, tickets: [{ id: "ticket-1", price: 20000 }] },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        // EF rejects (e.g. ineligible user, capacity full)
        return new Response(JSON.stringify({ error: "ineligible" }), { status: 422 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        DEFAULT_CONFIG,
        warnLog as Parameters<typeof simDiscoverAndApply>[2],
        [],
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    // No applications created — EF rejected
    assertEquals(result.applicationIds.length, 0);
    // Warning was logged for the rejection
    assertEquals(warnings.some((w) => w.includes("apply-event EF returned status=422")), true);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - empty feed for a user produces no applications",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  let applyCallCount = 0;

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [
            { id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" },
            { id: "user-2", gender: "female", birth_date: "1999-01-01", username: "user2" },
          ],
          error: null,
        }),
      },
    },
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url, init) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        const authHeader = (init.headers as Record<string, string>)["Authorization"] ?? "";
        // user1 gets empty feed, user2 gets one event
        if (authHeader.includes("user1")) {
          return new Response(JSON.stringify({ events: [] }), { status: 200 });
        }
        return new Response(
          JSON.stringify({
            events: [
              { id: "event-1", title: "이벤트 1", party: { title: "일반 파티" }, tickets: [{ id: "ticket-1", price: 20000 }] },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        applyCallCount++;
        return new Response(JSON.stringify({ type: "paid", application_id: `app-${applyCallCount}` }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        DEFAULT_CONFIG,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    // Only user2 applied (user1 had empty feed)
    assertEquals(result.applicationIds.length, 1);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - user_batch_size controls concurrent user processing",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  let appCounter = 0;

  // 6 users, batch_size=2 → 3 batches
  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: Array.from({ length: 6 }, (_, i) => ({
            id: `user-${i}`,
            gender: i % 2 === 0 ? "male" : "female",
            birth_date: "1998-01-01",
            username: `user${i}`,
          })),
          error: null,
        }),
      },
    },
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, user_batch_size: 2, max_apps_per_user: 1 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        return new Response(
          JSON.stringify({
            events: [
              { id: "event-1", title: "이벤트 1", party: { title: "일반 파티" }, tickets: [{ id: "ticket-1", price: 20000 }] },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        appCounter++;
        return new Response(JSON.stringify({ type: "paid", application_id: `app-${appCounter}` }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    // All 6 users processed across 3 batches of 2
    assertEquals(result.applicationIds.length, 6);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - skips when credentials not available",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const warnings: string[] = [];
  const warnLog = (entry: { level: string; message: string }) => {
    if (entry.level === "error" || entry.level === "warn") warnings.push(entry.message);
  };

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [{ id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" }],
          error: null,
        }),
      },
    },
  });

  // No SIM_USER_PASSWORD set, no supabaseUrl/anonKey — credentials unavailable
  const result = await simDiscoverAndApply(
    mock as unknown as SupabaseClient,
    DEFAULT_CONFIG,
    warnLog as Parameters<typeof simDiscoverAndApply>[2],
    ["event-1"],
    // supabaseUrl and anonKey intentionally omitted
  );

  // No applications created because credentials are missing
  assertEquals(result.applicationIds.length, 0);
  // A warning/error about missing credentials was logged
  assertEquals(warnings.some((w) => w.includes("SIM_USER_PASSWORD") || w.includes("supabaseUrl") || w.includes("cannot")), true);
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
// ── apply-event EF path tests (Fix #1323, #1324) ─────────────────────────────

Deno.test({
  name: "simDiscoverAndApply - applies via apply-event EF with correct parameters",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const efBodies: Record<string, unknown>[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [{ id: "user-42", gender: "male", birth_date: "1998-01-01", username: "user42" }],
          error: null,
        }),
      },
    },
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url, init) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-user-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        // Feed returns one event with ticket embedded
        return new Response(
          JSON.stringify({
            events: [
              { id: "target-event-1", title: "이벤트", party: { title: "일반 파티" }, tickets: [{ id: "ticket-99", price: 30000 }] },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        try {
          efBodies.push(JSON.parse((init.body as string) ?? "{}") as Record<string, unknown>);
        } catch {
          // intentionally empty
        }
        return new Response(JSON.stringify({ type: "paid", application_id: "ef-app-42" }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      const config: SimConfig = { ...DEFAULT_CONFIG, max_apps_per_user: 1 };
      const result = await simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      );

      // apply-event EF was called exactly once (1 user × max_apps_per_user=1)
      assertEquals(efBodies.length, 1);

      // EF body contains only event_id and ticket_id — server determines payment logic
      const body = efBodies[0];
      assertEquals(body.event_id, "target-event-1");
      assertEquals(body.ticket_id, "ticket-99");
      // EF body must NOT contain RPC-era parameters
      assertEquals(body.p_event_id, undefined);
      assertEquals(body.p_ticket_id, undefined);
      assertEquals(body.p_user_id, undefined);
      assertEquals(body.p_payment_id, undefined);
      assertEquals(body.p_payment_amount, undefined);
      assertEquals(body.p_verification_data, undefined);

      // Result includes the EF-returned application_id, classified as paid
      assertEquals(result.applicationIds, ["ef-app-42"]);
      assertEquals(result.paidApplicationIds, ["ef-app-42"]);
    });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - classifies free applications from apply-event EF response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [{ id: "user-free", gender: "male", birth_date: "1998-01-01", username: "userfree" }],
          error: null,
        }),
      },
    },
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-user-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        // price=0 free ticket in feed
        return new Response(
          JSON.stringify({
            events: [
              { id: "free-event-1", title: "무료 이벤트", party: { title: "일반 파티" }, tickets: [{ id: "ticket-free", price: 0 }] },
            ],
          }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/apply-event")) {
        // Server returns type=free for zero-price ticket
        return new Response(JSON.stringify({ type: "free", application_id: "free-app-1" }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      const config: SimConfig = { ...DEFAULT_CONFIG, max_apps_per_user: 1 };
      const result = await simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      );

      // Free application = partner approval pending, goes into pendingReviewApplicationIds
      assertEquals(result.applicationIds, ["free-app-1"]);
      assertEquals(result.paidApplicationIds, []);
      assertEquals(result.pendingReviewApplicationIds, ["free-app-1"]);
    });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});
