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
 *   - POST /functions/v1/user-cancel-order → returns configured response
 *
 * Fix #1327: payment-cancel EF → user-cancel-order EF로 전환.
 * Tests that use this mock must set sanitizeOps: false to avoid interval leak
 * failures caused by the supabase-js client's token refresh timer.
 */
function makeEfFetchMock(opts: {
  cancelOrderStatus?: number;
  cancelOrderBody?: unknown;
} = {}) {
  const { cancelOrderStatus = 200, cancelOrderBody = { success: true, data: {} } } = opts;

  const fetchMock = async (input: RequestInfo | URL, _init?: RequestInit): Promise<Response> => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
    if (url.includes("/auth/v1/token")) {
      return new Response(
        JSON.stringify({ access_token: "mock-jwt", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: { id: "user-id" } }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    // Fix #1327: user-cancel-order EF mock (replaces payment-cancel)
    if (url.includes("/functions/v1/user-cancel-order")) {
      return new Response(
        JSON.stringify(cancelOrderBody),
        { status: cancelOrderStatus, headers: { "Content-Type": "application/json" } },
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
 * Fix #1327: user-cancel-order EF handles cancellation, refund, and participant cleanup
 * atomically. The sim no longer calls event_applications.update or event_participants.delete
 * directly — those are now done by the EF.
 *
 * The mock reflects post-EF DB state: refund_status and refund_amount are set
 * by the EF (simulated via efRefundStatus/efRefundAmount in the select response).
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
} {
  const { paymentAmount, startTime, eventId, userId, username, efRefundStatus, efRefundAmount } = opts;

  const appStates: Record<string, { status?: string; refund_status?: string; refund_amount?: number }> = {};

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
      user_profiles: {
        select: () => ({
          data: { username },
          error: null,
        }),
      },
    },
  });

  return { mock, appStates };
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

    const { mock } = buildRefundMock({
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
    // Fix #1327: user-cancel-order EF handles status update + participant cleanup atomically
    // The sim no longer calls event_applications.update or event_participants.delete directly.
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

    const { mock } = buildRefundMock({
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

    // Fix #1327: user-cancel-order EF handles status update atomically; sim does not update DB directly
    assertEquals(result.refundedApplicationIds.length, 1);
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

    const { mock } = buildRefundMock({
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

    // Fix #1327: user-cancel-order EF handles status update atomically; sim does not update DB directly
    assertEquals(result.assertions.length, 1);
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

    const { mock } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-12h",
      userId: "user-1",
      username: "user_001",
      efRefundStatus: "failed",
      efRefundAmount: 0,
    });

    const fetchMock = makeEfFetchMock();
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-0pct-12h"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    // Fix #1327: user-cancel-order EF handles status update + participant cleanup atomically
    assertEquals(result.refundedApplicationIds.length, 1);
  },
});

// Fix #1327: participant cleanup is now handled atomically by user-cancel-order EF.
// The sim no longer calls event_participants.delete directly.
Deno.test({
  name: "simRefundRequests - EF succeeds → refund recorded (participant cleanup handled by EF)",
  sanitizeOps: false,
  sanitizeResources: false,
  fn: async () => {
    const paymentAmount = 5000;
    const startTime = daysFromNow(30);

    const { mock } = buildRefundMock({
      paymentAmount,
      startTime,
      eventId: "event-del",
      userId: "user-del",
      username: "user_del",
      efRefundStatus: "completed",
      efRefundAmount: paymentAmount,
    });

    const fetchMock = makeEfFetchMock();
    const result = await withMockedFetch(fetchMock, () =>
      simRefundRequests(
        mock as unknown as SupabaseClient,
        ["app-del-1"],
        noop,
        1.0,
        SUPABASE_URL,
        ANON_KEY,
      )
    );

    // EF handles participant cleanup atomically — sim only records the refund result
    assertEquals(result.refundedApplicationIds.length, 1);
    assertEquals(result.refundedApplicationIds[0], "app-del-1");
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

    const mock = createMockSupabaseClient({
      tables: {
        event_applications: {
          select: ({ filters }) => {
            const appId = filters["id"] as string;
            return {
              data: {
                id: appId,
                payment_amount: paymentAmount,
                payment_id: `pay-${appId}`,
                event_id: "event-20pct",
                user_id: "user-1",
                status: "paid",
                // Fix #1327: EF sets these values; sim reads them for assertion
                refund_status: "completed",
                refund_amount: paymentAmount,
              },
              error: null,
            };
          },
          update: () => ({ data: null, error: null }),
        },
        events: {
          select: () => ({
            data: { id: "event-20pct", start_time: startTime },
            error: null,
          }),
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

    // Fix #1327: only 1 app (20% of 5) processed; EF handles status update atomically
    assertEquals(result.refundedApplicationIds.length, 1);
    assertEquals(result.refundedApplicationIds[0], "app-a");
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

// Fix #1327: payment_id is no longer validated by sim (user-cancel-order EF uses event_id).
// Instead test that a partner username (starts with "partner_") triggers an error.
Deno.test("simRefundRequests - partner username → error logged, no refunds", async () => {
  const paymentAmount = 10000;
  const startTime = daysFromNow(30);

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => ({
          data: {
            id: filters["id"] as string,
            payment_amount: paymentAmount,
            payment_id: `pay-${filters["id"] as string}`,
            event_id: "event-partner-user",
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
          data: { id: "event-partner-user", start_time: startTime },
          error: null,
        }),
      },
      user_profiles: {
        // Fix #1327: partner_ username is rejected — user-cancel-order EF requires a real user
        select: () => ({ data: { username: "partner_001" }, error: null }),
      },
    },
  });

  const errors: string[] = [];
  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-partner-user"],
    (entry) => {
      if (entry.level === "error") errors.push(entry.message);
    },
    1.0,
    SUPABASE_URL,
    ANON_KEY,
  );

  assertEquals(result.refundedApplicationIds.length, 0);
  assertEquals(errors.length, 1);
  assertMatch(errors[0], /no valid user username/);
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

    // Fix #1327: payment-cancel → user-cancel-order EF
    const fetchMock = makeEfFetchMock({
      cancelOrderStatus: 500,
      cancelOrderBody: { error: "internal error" },
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
    // Fix #1327: error message updated to reflect user-cancel-order EF
    assertMatch(errors[0], /user-cancel-order EF returned 500/);
    // No status update was written to DB
    assertEquals(appStates["app-ef-fail"], undefined);
  },
});
