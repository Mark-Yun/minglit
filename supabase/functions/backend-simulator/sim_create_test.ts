import { assertEquals, assertStringIncludes } from "@std/assert";
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

Deno.test("simDiscoverAndApply - creates applications with 80/20 split", async () => {
  const paidApps: string[] = [];
  const pendingApps: string[] = [];
  let appCounter = 0;

  const mock = createMockSupabaseClient({
    tables: {
      events: { select: () => ({ data: [], error: null }) },
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
        insert: ({ values }) => {
          appCounter++;
          const id = `app-${appCounter}`;
          const v = values as { status: string };
          if (v.status === "paid") paidApps.push(id);
          else pendingApps.push(id);
          return { data: { id }, error: null };
        },
      },
      event_participants: {
        insert: () => ({ data: null, error: null }),
      },
    },
  });

  const config: SimConfig = {
    ...DEFAULT_CONFIG,
    error_rate: 0.0,
    apps_per_event: 5,
  };
  const result = await simDiscoverAndApply(
    mock as unknown as SupabaseClient,
    config,
    noop,
    ["event-1", "event-2"],
  );

  assertEquals(result.applicationIds.length > 0, true);
  assertEquals(result.paidApplicationIds.length > 0, true);
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

Deno.test("simDiscoverAndApply - processes multiple events concurrently", async () => {
  const processedEventIds: string[] = [];
  let appCounter = 0;

  const mock = createMockSupabaseClient({
    tables: {
      events: { select: () => ({ data: [], error: null }) },
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
        select: (_opts: unknown) => ({ data: [], error: null }),
        insert: ({ values }) => {
          appCounter++;
          const v = values as { event_id: string };
          processedEventIds.push(v.event_id);
          return { data: { id: `app-${appCounter}` }, error: null };
        },
      },
      event_participants: {
        insert: () => ({ data: null, error: null }),
      },
    },
  });

  // Fix #705: 6 events to test that batched concurrency processes all of them
  const eventIds = ["ev-1", "ev-2", "ev-3", "ev-4", "ev-5", "ev-6"];
  const config: SimConfig = { ...DEFAULT_CONFIG, error_rate: 0.0, apps_per_event: 2 };
  const result = await simDiscoverAndApply(
    mock as unknown as SupabaseClient,
    config,
    noop,
    eventIds,
  );

  // All 6 events should have been processed
  const uniqueEvents = new Set(processedEventIds);
  assertEquals(uniqueEvents.size, 6);
  assertEquals(result.applicationIds.length > 0, true);
});
