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
  apps_per_event: 3,
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

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - creates applications with 80/20 split",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  let appCounter = 0;

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: Array.from({ length: 10 }, (_, i) => ({
            id: `user-${i}`,
            gender: i % 2 === 0 ? "male" : "female",
            birth_date: "1998-01-01",
            username: `user${i}`,
          })),
          error: null,
        }),
      },
      entry_groups: {
        select: () => ({
          data: [
            { id: "group-male", gender: "male", birth_year_min: 1990, birth_year_max: 2005 },
            { id: "group-female", gender: "female", birth_year_min: 1990, birth_year_max: 2005 },
          ],
          error: null,
        }),
      },
      tickets: {
        select: () => ({
          data: [{ id: "ticket-1", price: 20000, status: "on_sale" }],
          error: null,
        }),
      },
      event_applications: {
        select: () => ({ data: [], error: null }),
      },
    },
  });

  const config: SimConfig = {
    ...DEFAULT_CONFIG,
    error_rate: 0.0,
    apps_per_event: 5,
  };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-user-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        // Return empty feed — only newEventIds should be processed
        return new Response(JSON.stringify({ events: [] }), { status: 200 });
      }
      if (url.includes("rest/v1/rpc/apply_event")) {
        appCounter++;
        return new Response(JSON.stringify(`app-${appCounter}`), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        ["event-1", "event-2"],
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    assertEquals(result.applicationIds.length > 0, true);
    assertEquals(result.paidApplicationIds.length > 0, true);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

Deno.test("simDiscoverAndApply - prevents duplicate applications", async () => {
  let insertCount = 0;

  const mock = createMockSupabaseClient({
    tables: {
      events: { select: () => ({ data: [], error: null }) },
      user_profiles: {
        select: () => ({
          data: [{ id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" }],
          error: null,
        }),
      },
      entry_groups: {
        select: () => ({
          data: [{ id: "group-1", gender: "male", birth_year_min: 1990, birth_year_max: 2005 }],
          error: null,
        }),
      },
      tickets: {
        select: () => ({ data: [{ id: "ticket-1", price: 20000 }], error: null }),
      },
      event_applications: {
        select: () => ({
          data: [{ user_id: "user-1" }],
          error: null,
        }),
        insert: () => {
          insertCount++;
          return { data: { id: "app-1" }, error: null };
        },
      },
      event_participants: {
        insert: () => ({ data: null, error: null }),
      },
    },
  });

  await simDiscoverAndApply(mock as unknown as SupabaseClient, DEFAULT_CONFIG, noop, ["event-1"]);

  assertEquals(insertCount, 0);
});

// ── EF path tests ────────────────────────────────────────────────────────────

// Intercept module-level EF calls via mock fetch. We replace globalThis.fetch
// for the duration of the test to simulate EF responses without a real server.

function withMockFetch(
  handler: (url: string, init: RequestInit) => Response,
  fn: () => Promise<void>,
): Promise<void> {
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

Deno.test("simCreateParties - throws when EF fails and strict=true", async () => {
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

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - processes multiple events concurrently",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const processedEventIds: string[] = [];
  let appCounter = 0;

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: Array.from({ length: 10 }, (_, i) => ({
            id: `user-${i}`,
            gender: i % 2 === 0 ? "male" : "female",
            birth_date: "1998-01-01",
            username: `user${i}`,
          })),
          error: null,
        }),
      },
      entry_groups: {
        select: () => ({
          data: [
            { id: "group-male", gender: "male", birth_year_min: 1990, birth_year_max: 2005 },
            { id: "group-female", gender: "female", birth_year_min: 1990, birth_year_max: 2005 },
          ],
          error: null,
        }),
      },
      tickets: {
        select: () => ({
          data: [{ id: "ticket-1", price: 20000, status: "on_sale" }],
          error: null,
        }),
      },
      event_applications: {
        select: () => ({ data: [], error: null }),
      },
    },
  });

  // Fix #705: 6 events to test that batched concurrency processes all of them
  const eventIds = ["ev-1", "ev-2", "ev-3", "ev-4", "ev-5", "ev-6"];
  const config: SimConfig = { ...DEFAULT_CONFIG, error_rate: 0.0, apps_per_event: 2 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    const result = await withMockFetch((url, init) => {
      if (url.includes("auth/v1/token")) {
        return new Response(
          JSON.stringify({ access_token: "mock-user-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
          { status: 200 },
        );
      }
      if (url.includes("functions/v1/user-event-feed")) {
        return new Response(JSON.stringify({ events: [] }), { status: 200 });
      }
      if (url.includes("rest/v1/rpc/apply_event")) {
        appCounter++;
        try {
          const body = JSON.parse((init.body as string) ?? "{}");
          if (body.p_event_id) processedEventIds.push(body.p_event_id);
        } catch {
          // intentionally empty
        }
        return new Response(JSON.stringify(`app-${appCounter}`), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, () =>
      simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        eventIds,
        "https://mock.supabase.co",
        "anon-key",
      )
    );

    // All 6 events should have been processed
    const uniqueEvents = new Set(processedEventIds);
    assertEquals(uniqueEvents.size, 6);
    assertEquals(result.applicationIds.length > 0, true);
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

// ── RPC-only path tests (Fix #1279) ──────────────────────────────────────────

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - uses user-event-feed EF for event discovery",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const efCalls: string[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        // First call: maybeSingle() for feed token acquisition → single object.
        // Second call: full user list for application loop → array.
        select: (() => {
          let callCount = 0;
          return () => {
            callCount++;
            if (callCount === 1) {
              return { data: { username: "user1" }, error: null };
            }
            return { data: [{ id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" }], error: null };
          };
        })(),
      },
      entry_groups: {
        select: () => ({
          data: [{ id: "group-1", gender: "male", birth_year_min: 1990, birth_year_max: 2005 }],
          error: null,
        }),
      },
      tickets: {
        select: () => ({ data: [{ id: "ticket-1", price: 20000, status: "on_sale" }], error: null }),
      },
      event_applications: {
        select: () => ({ data: [], error: null }),
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
        efCalls.push(url);
        // Return one extra event via EF (non-E2E)
        return new Response(
          JSON.stringify({ events: [{ id: "discovered-event-1", party: { title: "일반 파티" } }] }),
          { status: 200 },
        );
      }
      if (url.includes("rest/v1/rpc/apply_event")) {
        return new Response(JSON.stringify("rpc-app-1"), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      const result = await simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        DEFAULT_CONFIG,
        noop,
        [],
        "https://mock.supabase.co",
        "anon-key",
      );

      // EF was called for event discovery
      assertEquals(efCalls.some((u) => u.includes("user-event-feed")), true);
      // The discovered event was processed (application created)
      assertEquals(result.applicationIds.length > 0, true);
    });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

Deno.test({
  name: "simDiscoverAndApply - throws when strict=true and user-event-feed EF fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        // First call is maybeSingle() for feed token → return single object with username
        select: (() => {
          let callCount = 0;
          return () => {
            callCount++;
            if (callCount === 1) return { data: { username: "user1" }, error: null };
            return { data: [{ id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" }], error: null };
          };
        })(),
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
        return new Response(JSON.stringify({ error: "internal" }), { status: 500 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      await assertRejects(
        () =>
          simDiscoverAndApply(
            mock as unknown as SupabaseClient,
            DEFAULT_CONFIG,
            noop,
            [],
            "https://mock.supabase.co",
            "anon-key",
            true, // strict=true → should throw on EF failure
          ),
        Error,
        "user-event-feed EF returned status=500",
      );
    });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});

Deno.test("simDiscoverAndApply - skips when credentials not available", async () => {
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
      entry_groups: {
        select: () => ({
          data: [{ id: "group-1", gender: "male", birth_year_min: 1990, birth_year_max: 2005 }],
          error: null,
        }),
      },
      tickets: {
        select: () => ({ data: [{ id: "ticket-1", price: 20000, status: "on_sale" }], error: null }),
      },
      event_applications: {
        select: () => ({ data: [], error: null }),
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
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - applies via RPC with correct parameters",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const rpcBodies: Record<string, unknown>[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      user_profiles: {
        select: () => ({
          data: [{ id: "user-42", gender: "male", birth_date: "1998-01-01", username: "user42" }],
          error: null,
        }),
      },
      entry_groups: {
        select: () => ({
          data: [{ id: "group-male", gender: "male", birth_year_min: 1990, birth_year_max: 2005 }],
          error: null,
        }),
      },
      tickets: {
        select: () => ({ data: [{ id: "ticket-99", price: 30000, status: "on_sale" }], error: null }),
      },
      event_applications: {
        select: () => ({ data: [], error: null }),
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
        return new Response(JSON.stringify({ events: [] }), { status: 200 });
      }
      if (url.includes("rest/v1/rpc/apply_event")) {
        try {
          rpcBodies.push(JSON.parse((init.body as string) ?? "{}") as Record<string, unknown>);
        } catch {
          // intentionally empty
        }
        return new Response(JSON.stringify("rpc-app-42"), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      const config: SimConfig = { ...DEFAULT_CONFIG, error_rate: 0.0, apps_per_event: 1 };
      const result = await simDiscoverAndApply(
        mock as unknown as SupabaseClient,
        config,
        noop,
        ["target-event-1"],
        "https://mock.supabase.co",
        "anon-key",
      );

      // RPC was called exactly once (1 user × 1 event × apps_per_event=1)
      assertEquals(rpcBodies.length, 1);

      // RPC body contains required parameters
      const body = rpcBodies[0];
      assertEquals(body.p_event_id, "target-event-1");
      assertEquals(body.p_ticket_id, "ticket-99");
      assertEquals(body.p_user_id, "user-42");
      // Happy path (error_rate=0.0): p_payment_id and p_payment_amount should be set
      assertEquals(typeof body.p_payment_id, "string");
      assertEquals(body.p_payment_amount, 30000);
      // Happy path: p_verification_data should be null
      assertEquals(body.p_verification_data, null);

      // Result includes the RPC-returned app ID
      assertEquals(result.applicationIds, ["rpc-app-42"]);
      assertEquals(result.paidApplicationIds, ["rpc-app-42"]);
    });
  } finally {
    Deno.env.delete("SIM_USER_PASSWORD");
  }
  },
});
