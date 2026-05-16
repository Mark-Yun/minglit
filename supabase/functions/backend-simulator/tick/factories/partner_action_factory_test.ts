// partner_action_factory_test.ts — regression tests for PartnerActionFactory.generate() (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { PartnerActionFactory } from "./partner_action_factory.ts";
import { PartnerActionApprove } from "../actions/partner_action_approve.ts";
import { PartnerActionReject } from "../actions/partner_action_reject.ts";
import { PartnerActionCreateEvent } from "../actions/partner_action_create.ts";
import type { TickConfig } from "../tick_types.ts";

const SUPABASE_URL = "https://test.supabase.co";
const TOKEN = "test-token";
const PARTNER_ID = "partner-test";

const CONFIG: TickConfig = {
  usersPerTick: 10,
  negativeRate: 0.1,
  checkinRate: 0.9,
  maxAppsPerUser: 3,
  minScheduledEvents: 2,
};

/** Build mock client with full schema control for partner factory queries. */
function buildMock(opts: {
  parties?: Array<{ id: string }>;
  events?: Array<{ id: string }>;
  pending?: Array<{ id: string }>;
  scheduled?: Array<{ id: string }>;
}) {
  return createMockSupabaseClient({
    tables: {
      parties: {
        select: () => ({ data: opts.parties ?? [], error: null }),
      },
      events: {
        select: ({ filters }) => {
          // The factory queries events twice:
          //   1) all events for partyIds  → returns events[]
          //   2) scheduled events for partyIds → returns scheduled[]
          // Distinguish by presence of status filter.
          if (filters.status === "scheduled") {
            return { data: opts.scheduled ?? [], error: null };
          }
          return { data: opts.events ?? [], error: null };
        },
      },
      event_applications: {
        select: () => ({ data: opts.pending ?? [], error: null }),
      },
    },
  });
}

/** Replace Math.random for the duration of fn(), then restore. */
async function withFixedRandom<T>(value: number, fn: () => Promise<T>): Promise<T> {
  const original = Math.random;
  Math.random = () => value;
  try {
    return await fn();
  } finally {
    Math.random = original;
  }
}

// ============================================================
// Branch 1: no parties → immediate CreateEvent, skip rest
// ============================================================

Deno.test({
  name: "PartnerActionFactory.generate - emits exactly one CreateEvent when partner has no parties",
  fn: async () => {
    const mock = buildMock({ parties: [] });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await factory.generate(mock as unknown as SupabaseClient);

    assertEquals(actions.length, 1);
    assertEquals(actions[0] instanceof PartnerActionCreateEvent, true);
  },
});

// ============================================================
// Branch 2: pending_review apps → Approve/Reject per app
// ============================================================

Deno.test({
  name: "PartnerActionFactory.generate - emits Approve for every pending app when random < 0.9",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [{ id: "event-1" }],
      pending: [{ id: "app-1" }, { id: "app-2" }, { id: "app-3" }],
      scheduled: [{ id: "sch-1" }, { id: "sch-2" }],
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await withFixedRandom(0.5, () => factory.generate(mock as unknown as SupabaseClient));

    const approves = actions.filter((a) => a instanceof PartnerActionApprove);
    const rejects = actions.filter((a) => a instanceof PartnerActionReject);
    assertEquals(approves.length, 3, "all 3 pending apps must become Approve actions when random < 0.9");
    assertEquals(rejects.length, 0);
  },
});

Deno.test({
  name: "PartnerActionFactory.generate - emits Reject for every pending app when random >= 0.9",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [{ id: "event-1" }],
      pending: [{ id: "app-1" }, { id: "app-2" }],
      scheduled: [{ id: "sch-1" }, { id: "sch-2" }],
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await withFixedRandom(0.95, () => factory.generate(mock as unknown as SupabaseClient));

    const approves = actions.filter((a) => a instanceof PartnerActionApprove);
    const rejects = actions.filter((a) => a instanceof PartnerActionReject);
    assertEquals(approves.length, 0);
    assertEquals(rejects.length, 2, "all 2 pending apps must become Reject actions when random >= 0.9");
  },
});

Deno.test({
  name: "PartnerActionFactory.generate - every pending app is handled (no silent drops)",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [{ id: "event-1" }],
      pending: [{ id: "app-1" }, { id: "app-2" }, { id: "app-3" }, { id: "app-4" }, { id: "app-5" }],
      scheduled: [{ id: "sch-1" }, { id: "sch-2" }],
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await factory.generate(mock as unknown as SupabaseClient);
    const decisionActions = actions.filter(
      (a) => a instanceof PartnerActionApprove || a instanceof PartnerActionReject,
    );
    assertEquals(decisionActions.length, 5, "every pending app must produce a decision action (Approve or Reject)");
  },
});

// ============================================================
// Branch 3: scheduled events threshold → optional CreateEvent
// ============================================================

Deno.test({
  name: "PartnerActionFactory.generate - emits CreateEvent when scheduled < minScheduledEvents",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [{ id: "event-1" }],
      pending: [],
      scheduled: [{ id: "sch-1" }], // 1 < minScheduledEvents(2)
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await factory.generate(mock as unknown as SupabaseClient);

    const creates = actions.filter((a) => a instanceof PartnerActionCreateEvent);
    assertEquals(creates.length, 1, "scheduled below minimum must trigger a single CreateEvent");
  },
});

Deno.test({
  name: "PartnerActionFactory.generate - no CreateEvent when scheduled >= minScheduledEvents",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [{ id: "event-1" }],
      pending: [],
      scheduled: [{ id: "sch-1" }, { id: "sch-2" }], // 2 == minScheduledEvents(2)
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await factory.generate(mock as unknown as SupabaseClient);

    const creates = actions.filter((a) => a instanceof PartnerActionCreateEvent);
    assertEquals(creates.length, 0, "scheduled at or above minimum must NOT trigger CreateEvent");
  },
});

Deno.test({
  name: "PartnerActionFactory.generate - respects custom minScheduledEvents from config",
  fn: async () => {
    const stricterConfig: TickConfig = { ...CONFIG, minScheduledEvents: 5 };
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [{ id: "event-1" }],
      pending: [],
      scheduled: [{ id: "sch-1" }, { id: "sch-2" }, { id: "sch-3" }], // 3 < 5
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, stricterConfig, SUPABASE_URL);

    const actions = await factory.generate(mock as unknown as SupabaseClient);

    const creates = actions.filter((a) => a instanceof PartnerActionCreateEvent);
    assertEquals(creates.length, 1, "custom higher minScheduledEvents must still gate CreateEvent");
  },
});

// ============================================================
// Combined: pending decisions + below-threshold CreateEvent in same tick
// ============================================================

Deno.test({
  name: "PartnerActionFactory.generate - combines decisions and CreateEvent in one batch",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }, { id: "party-2" }],
      events: [{ id: "event-1" }, { id: "event-2" }],
      pending: [{ id: "app-1" }, { id: "app-2" }],
      scheduled: [{ id: "sch-1" }], // below min(2)
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await withFixedRandom(0.5, () => factory.generate(mock as unknown as SupabaseClient));

    const approves = actions.filter((a) => a instanceof PartnerActionApprove);
    const creates = actions.filter((a) => a instanceof PartnerActionCreateEvent);
    assertEquals(approves.length, 2, "both pending apps approved (random=0.5 < 0.9)");
    assertEquals(creates.length, 1, "CreateEvent appended because scheduled < min");
    assertEquals(actions.length, 3);
  },
});

// ============================================================
// Edge: parties exist but no events yet (early partner state)
// ============================================================

Deno.test({
  name: "PartnerActionFactory.generate - skips pending-app query when partner has parties but zero events",
  fn: async () => {
    const mock = buildMock({
      parties: [{ id: "party-1" }],
      events: [],
      pending: [{ id: "app-stale" }], // would-be result if queried; must not be seen
      scheduled: [], // below min → triggers CreateEvent
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    const actions = await factory.generate(mock as unknown as SupabaseClient);

    // No events → no Approve/Reject path; only CreateEvent from threshold check
    const decisions = actions.filter(
      (a) => a instanceof PartnerActionApprove || a instanceof PartnerActionReject,
    );
    const creates = actions.filter((a) => a instanceof PartnerActionCreateEvent);
    assertEquals(decisions.length, 0, "decision actions must not be emitted when partner has no events yet");
    assertEquals(creates.length, 1, "CreateEvent still emitted because scheduled below minimum");
  },
});

// ============================================================
// Error propagation
// ============================================================

Deno.test({
  name: "PartnerActionFactory.generate - throws when parties query errors",
  fn: async () => {
    const mock = createMockSupabaseClient({
      tables: {
        parties: { select: () => ({ data: null, error: { message: "db down" } }) },
      },
    });
    const factory = new PartnerActionFactory(PARTNER_ID, TOKEN, CONFIG, SUPABASE_URL);

    let caught: Error | null = null;
    try {
      await factory.generate(mock as unknown as SupabaseClient);
    } catch (e) {
      caught = e as Error;
    }
    assertEquals(caught !== null, true, "must surface DB error rather than silently return empty");
    assertEquals(caught?.message.includes("db down"), true);
  },
});
