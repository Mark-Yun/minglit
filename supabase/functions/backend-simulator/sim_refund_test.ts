import { assertEquals, assertMatch } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { withMockedFetch } from "../_test_utils/mock_http.ts";
import { simRefundRequests } from "./sim_refund.ts";
import { simCalcRefund } from "./sim_assertions.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};
const SUPABASE_URL = "https://test.supabase.co";
const ANON_KEY = "test-anon-key";

/**
 * Creates a fetch mock that handles:
 *   - POST /auth/v1/token → returns a JWT (triggers supabase-js token refresh interval)
 *   - POST /functions/v1/payment-cancel → returns configured response
 *
 * Tests that use this mock must set sanitizeOps: false to avoid interval leak
 * failures caused by the supabase-js client's token refresh timer.
 */
function makeEfFetchMock(opts: {
  paymentCancelStatus?: number;
  paymentCancelBody?: unknown;
} = {}) {
  const { paymentCancelStatus = 200, paymentCancelBody = { success: true, data: {} } } = opts;

  const fetchMock = async (input: RequestInfo | URL, _init?: RequestInit): Promise<Response> => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
    if (url.includes("/auth/v1/token")) {
      return new Response(
        JSON.stringify({ access_token: "mock-jwt", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: { id: "user-id" } }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    if (url.includes("/functions/v1/payment-cancel")) {
      return new Response(
        JSON.stringify(paymentCancelBody),
        { status: paymentCancelStatus, headers: { "Content-Type": "application/json" } },
      );
    }
    throw new Error(`Unhandled fetch in test: ${url}`);
  };

  return fetchMock as typeof fetch;
}

function daysFromNow(days: number): string {
  const d = new Date();
  d.setTime(d.getTime() + days * 24 * 60 * 60 * 1000);
  return d.toISOString();
}

function hoursFromNow(hours: number): string {
  const d = new Date();
  d.setTime(d.getTime() + hours * 60 * 60 * 1000);
  return d.toISOString();
}

/**
 * Builds a mock supabase client for the standard EF-based refund flow.
 *
 * The mock reflects post-EF DB state: refund_status and refund_amount are set
 * by the EF (simulated via efRefundStatus/efRefundAmount in the select response).
 * The sim itself then calls update({status:'cancelled'}) and delete on event_participants.
 */
function buildRefundMock(opts: {
  paymentAmount: number;
  startTime: string;
  eventId: string;
  userId: string;
  username: string;
  efRefundStatus: string;
  efRefundAmount: number;
}): {
  mock: ReturnType<typeof createMockSupabaseClient>;
  appStates: Record<string, { status?: string; refund_status?: string; refund_amount?: number }>;
  deletedParticipants: Array<{ event_id: string; user_id: string }>;
} {
  const { paymentAmount, startTime, eventId, userId, username, efRefundStatus, efRefundAmount } = opts;

  const appStates: Record<string, { status?: string; refund_status?: string; refund_amount?: number }> = {};
  const deletedParticipants: Array<{ event_id: string; user_id: string }> = [];

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const state = appStates[appId];
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              payment_id: `pay-${appId}`,
              event_id: eventId,
              user_id: userId,
              status: state?.status ?? "paid",
              // After EF runs, DB has these values. Sim reads them for assertion.
              refund_status: state?.refund_status ?? efRefundStatus,
              refund_amount: state?.refund_amount ?? efRefundAmount,
            },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as Record<string, unknown>;
          appStates[appId] = {
            ...appStates[appId],
            ...(v.status !== undefined ? { status: v.status as string } : {}),
            ...(v.refund_status !== undefined ? { refund_status: v.refund_status as string } : {}),
            ...(v.refund_amount !== undefined ? { refund_amount: v.refund_amount as number } : {}),
          };
          return { data: null, error: null };
        },
      },
      events: {
        select: () => ({
          data: { id: eventId, start_time: startTime },
          error: null,
        }),
      },
      event_participants: {
        delete: ({ filters }) => {
          deletedParticipants.push({
            event_id: filters["event_id"] as string,
            user_id: filters["user_id"] as string,
          });
          return { data: null, error: null };
        },
      },
      user_profiles: {
        select: () => ({
          data: { username },
          error: null,
        }),
      },
    },
  });

  return { mock, appStates, deletedParticipants };
}

// ============================================================
// Tests: early-exit cases (no EF call needed)
// ============================================================

Deno.test("simRefundRequests - empty list returns empty result", async () => {
  const mock = createMockSupabaseClient({});
  const result = await simRefundRequests(mock as unknown as SupabaseClient, [], noop);

  assertEquals(result.refundedApplicationIds, []);
  assertEquals(result.assertions, []);
});

Deno.test("simRefundRequests - refundRate=0.0 → no refunds processed", async () => {
  const mock = createMockSupabaseClient({});
  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-1", "app-2", "app-3"],
    noop,
    0.0,
  );

  assertEquals(result.refundedApplicationIds, []);
  assertEquals(result.assertions, []);
});

// ============================================================
// Tests: EF-only refund path
// sanitizeOps: false required — supabase-js createClient starts a token refresh
// interval after signIn succeeds, which outlives the test scope.
// ============================================================

Deno.test({
  name: "simRefundRequests - 100% refund (event +30 days) → refund via EF",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 10000;
    const startTime = daysFromNow(30);
    const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

    assertEquals(expectedCalc.refund_percentage, 100);
    assertEquals(expectedCalc.refund_amount, paymentAmount);

    const { mock, appStates, deletedParticipants } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-30d",
      userId: "user-1",
      username: "user_001",
      efRefundStatus: "completed",
      efRefundAmount: paymentAmount,
    });

    const fetchMock = makeEfFetchMock();
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-100pct"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    assertEquals(result.refundedApplicationIds.length, 1);
    assertEquals(result.refundedApplicationIds[0], "app-100pct");
    // sim sets status='cancelled' after EF succeeds (EF does not touch status field)
    assertEquals(appStates["app-100pct"].status, "cancelled");
    // participant deleted explicitly (no DB trigger handles this on refund)
    assertEquals(deletedParticipants.length, 1);
    assertEquals(deletedParticipants[0].event_id, "event-30d");
    assertEquals(deletedParticipants[0].user_id, "user-1");
  },
});

Deno.test({
  name: "simRefundRequests - 0% refund (event +5 days, binary policy) → refund_amount=0 via EF",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 10000;
    const startTime = daysFromNow(5);
    const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

    assertEquals(expectedCalc.refund_percentage, 0);
    assertEquals(expectedCalc.refund_amount, 0);

    const { mock, appStates } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-5d",
      userId: "user-1",
      username: "user_001",
      efRefundStatus: "failed",
      efRefundAmount: 0,
    });

    const fetchMock = makeEfFetchMock();
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-0pct-5d"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    assertEquals(result.refundedApplicationIds.length, 1);
    assertEquals(appStates["app-0pct-5d"].status, "cancelled");
  },
});

Deno.test({
  name: "simRefundRequests - 0% refund (event +2 days, binary policy) → refund_amount=0 via EF",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 9999;
    const startTime = daysFromNow(2);
    const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

    assertEquals(expectedCalc.refund_percentage, 0);
    assertEquals(expectedCalc.refund_amount, 0);

    const { mock, appStates } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-2d",
      userId: "user-1",
      username: "user_001",
      efRefundStatus: "failed",
      efRefundAmount: 0,
    });

    const fetchMock = makeEfFetchMock();
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-0pct-2d"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    assertEquals(result.assertions.length, 1);
    assertEquals(appStates["app-0pct-2d"].status, "cancelled");
  },
});

Deno.test({
  name: "simRefundRequests - 0% refund (+12 hours) → refund_amount=0 via EF",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 10000;
    const startTime = hoursFromNow(12);
    const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

    assertEquals(expectedCalc.refund_percentage, 0);
    assertEquals(expectedCalc.refund_amount, 0);

    const { mock, appStates, deletedParticipants } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-12h",
      userId: "user-1",
      username: "user_001",
      efRefundStatus: "failed",
      efRefundAmount: 0,
    });

    const fetchMock = makeEfFetchMock();
    await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-0pct-12h"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    assertEquals(appStates["app-0pct-12h"].status, "cancelled");
    assertEquals(deletedParticipants.length, 1);
  },
});

Deno.test({
  name: "simRefundRequests - participant is deleted after EF succeeds",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 5000;
    const startTime = daysFromNow(30);

    const { mock, deletedParticipants } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-del",
      userId: "user-del",
      username: "user_del",
      efRefundStatus: "completed",
      efRefundAmount: paymentAmount,
    });

    const fetchMock = makeEfFetchMock();
    await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-del-1"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    assertEquals(deletedParticipants.length, 1);
    assertEquals(deletedParticipants[0].event_id, "event-del");
    assertEquals(deletedParticipants[0].user_id, "user-del");
  },
});

Deno.test({
  name: "simRefundRequests - 20% of 5 apps → 1 refunded via EF",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 10000;
    const startTime = daysFromNow(30);
    const appIds = ["app-a", "app-b", "app-c", "app-d", "app-e"];
    const cancelledApps: string[] = [];

    const mock = createMockSupabaseClient({
      tables: {
        event_applications: {
          select: ({ filters }) => {
            const appId = filters["id"] as string;
            const wasCancelled = cancelledApps.includes(appId);
            return {
              data: {
                id: appId,
                payment_amount: paymentAmount,
                payment_id: `pay-${appId}`,
                event_id: "event-20pct",
                user_id: "user-1",
                status: wasCancelled ? "cancelled" : "paid",
                refund_status: wasCancelled ? "completed" : "none",
                refund_amount: wasCancelled ? paymentAmount : 0,
              },
              error: null,
            };
          },
          update: ({ values, filters }) => {
            const appId = filters["id"] as string;
            const v = values as Record<string, unknown>;
            if (v.status === "cancelled") cancelledApps.push(appId);
            return { data: null, error: null };
          },
        },
        events: {
          select: () => ({
            data: { id: "event-20pct", start_time: startTime },
            error: null,
          }),
        },
        event_participants: {
          delete: () => ({ data: null, error: null }),
        },
        user_profiles: {
          select: () => ({
            data: { username: "user_001" },
            error: null,
          }),
        },
      },
    });

    const fetchMock = makeEfFetchMock();
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        appIds,
        noop,
        0.2,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    assertEquals(result.refundedApplicationIds.length, 1);
    assertEquals(cancelledApps.length, 1);
    assertEquals(cancelledApps[0], "app-a");
  },
});

// ============================================================
// Tests: error cases — EF failure throws (no direct DB fallback)
// ============================================================

Deno.test({ name: "simRefundRequests - missing supabaseUrl → error logged, no refunds", sanitizeOps: false, sanitizeResources: false, fn: async () => {
  const paymentAmount = 10000;
  const startTime = daysFromNow(30);

  const { mock } = buildRefundMock({
    paymentAmount,
    startTime,
    eventId: "event-err",
    userId: "user-1",
    username: "user_001",
    efRefundStatus: "none",
    efRefundAmount: 0,
  });

  const errors: string[] = [];
  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-no-url"],
    (entry) => {
      if (entry.level === "error") errors.push(entry.message);
    },
    1.0,
    undefined, // supabaseUrl omitted → must throw
    ANON_KEY,
  );

  assertEquals(result.refundedApplicationIds.length, 0);
  assertEquals(errors.length, 1);
  assertMatch(errors[0], /supabaseUrl\/anonKey required/);
}});

Deno.test("simRefundRequests - missing payment_id → error logged, no refunds", async () => {
  const paymentAmount = 10000;
  const startTime = daysFromNow(30);

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => ({
          data: {
            id: filters["id"] as string,
            payment_amount: paymentAmount,
            payment_id: null, // no payment_id → must throw
            event_id: "event-no-pid",
            user_id: "user-1",
            status: "paid",
            refund_status: "none",
            refund_amount: 0,
          },
          error: null,
        }),
        update: () => ({ data: null, error: null }),
      },
      events: {
        select: () => ({
          data: { id: "event-no-pid", start_time: startTime },
          error: null,
        }),
      },
      event_participants: {
        delete: () => ({ data: null, error: null }),
      },
      user_profiles: {
        select: () => ({ data: { username: "user_001" }, error: null }),
      },
    },
  });

  const errors: string[] = [];
  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-no-pid"],
    (entry) => {
      if (entry.level === "error") errors.push(entry.message);
    },
    1.0,
    SUPABASE_URL,
    ANON_KEY,
  );

  assertEquals(result.refundedApplicationIds.length, 0);
  assertEquals(errors.length, 1);
  assertMatch(errors[0], /payment_id is null/);
});

Deno.test({
  name: "simRefundRequests - EF returns non-200 → error logged, no refunds, no DB fallback",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 10000;
    const startTime = daysFromNow(30);

    const { mock, appStates } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-ef-fail",
      userId: "user-1",
      username: "user_001",
      efRefundStatus: "none",
      efRefundAmount: 0,
    });

    const fetchMock = makeEfFetchMock({
      paymentCancelStatus: 500,
      paymentCancelBody: { error: "internal error" },
    });

    const errors: string[] = [];
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-ef-fail"],
        (entry) => {
          if (entry.level === "error") errors.push(entry.message);
        },
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    // No refunds succeed — error thrown, no direct DB fallback
    assertEquals(result.refundedApplicationIds.length, 0);
    assertEquals(errors.length, 1);
    assertMatch(errors[0], /payment-cancel EF returned 500/);
    // No status update was written to DB
    assertEquals(appStates["app-ef-fail"], undefined);
  },
});
