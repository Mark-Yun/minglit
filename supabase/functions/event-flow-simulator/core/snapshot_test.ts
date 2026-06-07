import { assertEquals, assertRejects } from "@std/assert";
import {
  createMockSupabaseClient,
  type MockRange,
} from "../../_test_utils/mock_supabase_client.ts";
import { buildSnapshot } from "./snapshot.ts";

type Row = Record<string, unknown>;

function pageRows<T>(rows: T[], range?: MockRange): T[] {
  if (!range) return rows;
  return rows.slice(range.from, range.to + 1);
}

function filterIn<T extends Row>(
  rows: T[],
  filters: Record<string, unknown>,
  column: string,
): T[] {
  const values = filters[column];
  if (!Array.isArray(values)) return rows;
  return rows.filter((row) => values.includes(row[column]));
}

Deno.test({
  name:
    "buildSnapshot paginates parties so late scheduled events remain visible",
  fn: async () => {
    const parties = Array.from({ length: 1001 }, (_, index) => ({
      id: `party-${index}`,
      partner_id: `partner-${index}`,
      status: "active",
    }));
    const events = [
      {
        id: "event-late",
        party_id: "party-1000",
        status: "scheduled",
        start_time: new Date(Date.now() + 10 * 86_400_000).toISOString(),
      },
    ];
    const tickets = [
      {
        id: "ticket-late",
        event_id: "event-late",
        price: 15000,
        status: "on_sale",
        quantity: 20,
        sold_count: 3,
      },
    ];
    const blocks = [
      {
        user_id: "user-1",
        target_id: "partner-1000",
        target_type: "partner",
      },
    ];

    const supabase = createMockSupabaseClient({
      tables: {
        parties: {
          select: ({ range }) => ({
            data: pageRows(parties, range),
            error: null,
          }),
        },
        events: {
          select: ({ range }) => ({
            data: pageRows(events, range),
            error: null,
          }),
        },
        tickets: {
          select: ({ filters, range }) => ({
            data: pageRows(filterIn(tickets, filters, "event_id"), range),
            error: null,
          }),
        },
        event_applications: {
          select: () => ({ data: [], error: null }),
        },
        event_participants: {
          select: () => ({ data: [], error: null }),
        },
        match_votes: {
          select: () => ({ data: [], error: null }),
        },
        social_interactions: {
          select: ({ filters, range }) => {
            assertEquals(filters.interaction_type, "block");
            assertEquals(filters.target_type, "partner");
            return {
              data: pageRows(filterIn(blocks, filters, "target_id"), range),
              error: null,
            };
          },
        },
      },
    });

    const snapshot = await buildSnapshot(
      // deno-lint-ignore no-explicit-any
      supabase as any,
    );

    assertEquals(snapshot.parties.length, 1001);
    assertEquals(snapshot.events.length, 1);
    assertEquals(snapshot.events[0].id, "event-late");
    assertEquals(snapshot.events[0].tickets, [
      {
        id: "ticket-late",
        price: 15000,
        status: "on_sale",
        quantity: 20,
        sold_count: 3,
      },
    ]);
    assertEquals(snapshot.blocks, blocks);
  },
});

Deno.test({
  name: "buildSnapshot surfaces select errors",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: {
        parties: {
          select: () => ({
            data: null,
            error: { message: "load failed" },
          }),
        },
      },
    });

    await assertRejects(
      () =>
        buildSnapshot(
          // deno-lint-ignore no-explicit-any
          supabase as any,
        ),
      Error,
      "buildSnapshot: failed to load parties: load failed",
    );
  },
});
