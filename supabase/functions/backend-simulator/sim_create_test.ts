import { assertEquals, assertExists, assertRejects } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simCreateParties, simCreateDisplayEvents, simDiscoverAndApply } from "./sim_create.ts";
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
};

const noop = () => {};

// ── simCreateParties / simCreateDisplayEvents EF-only tests ──────────────────

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
  name: "simCreateParties - creates parties and events via EF and returns IDs",
  fn: async () => {
  const efCalls: { url: string; body: unknown }[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [{ id: "tmpl-1", name: "일반" }], error: null }) },
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
  name: "simCreateParties - event EF body includes min_confirmed_count and metadata",
  fn: async () => {
  const eventEfBodies: Record<string, unknown>[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [{ id: "tmpl-1", name: "일반" }], error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 1 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url, init) => {
      if (url.includes("auth/v1/token")) {
        return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
      }
      if (url.includes("partner-manage-party")) {
        return new Response(JSON.stringify({ success: true, party_id: "ef-party-1" }), { status: 200 });
      }
      if (url.includes("partner-manage-event")) {
        try {
          eventEfBodies.push(JSON.parse((init.body as string) ?? "{}") as Record<string, unknown>);
        } catch { /* intentionally empty */ }
        return new Response(JSON.stringify({ success: true, event_id: "ef-event-1" }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      await simCreateParties(
        mock as unknown as SupabaseClient,
        config,
        noop,
        "https://mock.supabase.co",
        "anon-key",
      );

      assertEquals(eventEfBodies.length, 1);
      const eventBody = eventEfBodies[0].event as Record<string, unknown>;
      assertEquals(eventBody.min_confirmed_count, 4);
      assertEquals((eventBody.metadata as Record<string, unknown>).show_participant_list, true);
      assertEquals((eventBody.metadata as Record<string, unknown>).visibility, "public");
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
  name: "simCreateParties - throws when EF fails",
  fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [], error: null }) },
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

Deno.test({
  name: "simCreateParties - throws when SIM_USER_PASSWORD not set",
  fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
    },
  });

  // Ensure SIM_USER_PASSWORD is not set
  Deno.env.delete("SIM_USER_PASSWORD");

  await assertRejects(
    () => simCreateParties(
      mock as unknown as SupabaseClient,
      DEFAULT_CONFIG,
      noop,
      "https://mock.supabase.co",
      "anon-key",
    ),
    Error,
    "SIM_USER_PASSWORD is required",
  );
  },
});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simCreateParties - creates 4 distinct start_time zones via EF",
  fn: async () => {
  const eventStartTimes: string[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: { id: "loc-1" }, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [{ id: "tmpl-1", name: "일반" }], error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  const config: SimConfig = { ...DEFAULT_CONFIG, party_count: 1, events_per_party: 4 };

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url, init) => {
      if (url.includes("auth/v1/token")) {
        return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
      }
      if (url.includes("partner-manage-party")) {
        return new Response(JSON.stringify({ success: true, party_id: "ef-party-1" }), { status: 200 });
      }
      if (url.includes("partner-manage-event")) {
        try {
          const body = JSON.parse((init.body as string) ?? "{}") as { event?: { start_time?: string } };
          if (body.event?.start_time) eventStartTimes.push(body.event.start_time);
        } catch { /* intentionally empty */ }
        return new Response(JSON.stringify({ success: true, event_id: `ef-event-${eventStartTimes.length}` }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      await simCreateParties(
        mock as unknown as SupabaseClient,
        config,
        noop,
        "https://mock.supabase.co",
        "anon-key",
      );

      assertEquals(eventStartTimes.length, 4);
      const now = Date.now();
      const times = eventStartTimes.map((t) => new Date(t).getTime());

      const plusTwoDays = now + 2 * 24 * 60 * 60 * 1000;
      const plusFiveDays = now + 5 * 24 * 60 * 60 * 1000;
      const plusThirtyDays = now + 30 * 24 * 60 * 60 * 1000;
      const plusTwelveHours = now + 12 * 60 * 60 * 1000;

      assertEquals(times.every((t) => t - now > 2 * 60 * 60 * 1000), true);
      assertEquals(times.some((t) => t > plusThirtyDays - 60000), true);
      assertEquals(times.some((t) => t > plusFiveDays - 60000 && t < plusFiveDays + 60000), true);
      assertEquals(times.some((t) => t > plusTwoDays - 60000 && t < plusTwoDays + 60000), true);
      assertEquals(times.some((t) => t > plusTwelveHours - 60000 && t < plusTwelveHours + 60000), true);
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
  name: "simCreateDisplayEvents - creates display parties and events via EF",
  fn: async () => {
  const efCalls: { url: string; body: unknown }[] = [];
  let partyCallCount = 0;
  let eventCallCount = 0;

  const mock = createMockSupabaseClient({
    tables: {
      parties: { select: () => ({ data: [], error: null }) },
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: null, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [{ id: "tmpl-display-1", name: "일반 티켓" }], error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url, init) => {
      const body = JSON.parse((init.body as string) ?? "{}");
      efCalls.push({ url, body });

      if (url.includes("auth/v1/token")) {
        return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
      }
      if (url.includes("partner-manage-party")) {
        partyCallCount++;
        return new Response(JSON.stringify({ success: true, party_id: `ef-display-party-${partyCallCount}` }), { status: 200 });
      }
      if (url.includes("partner-manage-event")) {
        eventCallCount++;
        return new Response(JSON.stringify({ success: true, event_id: `ef-display-event-${eventCallCount}` }), { status: 200 });
      }
      return new Response(JSON.stringify({}), { status: 404 });
    }, async () => {
      const result = await simCreateDisplayEvents(
        mock as unknown as SupabaseClient,
        noop,
        "https://mock.supabase.co",
        "anon-key",
      );

      // 5 display scenarios → 5 parties, 2 events each = 10 events
      assertEquals(result.displayPartyIds.length, 5);
      assertEquals(result.displayEventIds.length, 10);
      assertEquals(partyCallCount, 5);
      assertEquals(eventCallCount, 10);

      // Verify event payloads include title
      const eventCalls = efCalls.filter(c => c.url.includes("partner-manage-event"));
      for (const call of eventCalls) {
        const body = call.body as { event?: { title?: string } };
        assertExists(body.event?.title, "display event must have a title");
      }
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
  name: "simCreateDisplayEvents - skips when display parties already exist",
  fn: async () => {
  let efCallCount = 0;

  // Return 5 existing parties (all DISPLAY_SCENARIOS already exist)
  const mock = createMockSupabaseClient({
    tables: {
      parties: {
        select: () => ({
          data: Array.from({ length: 5 }, (_, i) => ({ id: `existing-party-${i}` })),
          error: null,
        }),
      },
    },
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url) => {
      if (!url.includes("auth/v1/token")) efCallCount++;
      return new Response(JSON.stringify({}), { status: 200 });
    }, async () => {
      const result = await simCreateDisplayEvents(
        mock as unknown as SupabaseClient,
        noop,
        "https://mock.supabase.co",
        "anon-key",
      );

      // No EF calls made — dedup check triggered early return
      assertEquals(efCallCount, 0);
      assertEquals(result.displayPartyIds.length, 0);
      assertEquals(result.displayEventIds.length, 0);
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
  name: "simCreateDisplayEvents - throws when display party EF fails",
  fn: async () => {
  const mock = createMockSupabaseClient({
    tables: {
      parties: { select: () => ({ data: [], error: null }) },
      partners: { select: () => ({ data: [{ id: "partner-1" }], error: null }) },
      locations: { select: () => ({ data: null, error: null }) },
      partner_members: { select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }) },
      ticket_templates: { select: () => ({ data: [], error: null }) },
    },
    authAdminGetUserById: (_userId: string) => ({ data: { user: { email: "partner1@test.com" } }, error: null }),
  });

  Deno.env.set("SIM_USER_PASSWORD", "test-password");
  try {
    await withMockFetch((url) => {
      if (url.includes("auth/v1/token")) {
        return new Response(JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }), { status: 200 });
      }
      return new Response(JSON.stringify({ error: "internal" }), { status: 500 });
    }, async () => {
      await assertRejects(
        () => simCreateDisplayEvents(
          mock as unknown as SupabaseClient,
          noop,
          "https://mock.supabase.co",
          "anon-key",
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

// ── simDiscoverAndApply — user-centric loop tests (Fix #1323) ────────────────

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
Deno.test({
  name: "simDiscoverAndApply - basic user-centric flow: users discover and apply via own feed",
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

// Fix #1283: credentials 누락 시 즉시 throw (strict 제거 후 유일한 동작)
// sanitizeOps disabled: preceding test (@supabase/auth-js setInterval leak) completes timers here
Deno.test({ name: "simDiscoverAndApply - throws when credentials not available", fn: async () => {
  const mock = createMockSupabaseClient({});

  // No SIM_USER_PASSWORD set — throws immediately
  await assertRejects(
    () => simDiscoverAndApply(
      mock as unknown as SupabaseClient,
      DEFAULT_CONFIG,
      noop,
      ["event-1"],
    ),
    Error,
    "SIM_USER_PASSWORD not set",
  );
}});

// sanitizeResources/sanitizeOps disabled: @supabase/auth-js internally calls setInterval for
// token auto-refresh even when persistSession=false. The interval leaks within the test but is
// harmless — suppressing the leak check is correct here rather than patching the library.
// ── apply-event EF path tests (Fix #1323, #1324) ─────────────────────────────

Deno.test({
  name: "simDiscoverAndApply - applies via apply-event EF with correct parameters",
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
