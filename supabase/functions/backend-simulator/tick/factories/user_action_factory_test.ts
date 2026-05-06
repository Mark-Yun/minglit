// user_action_factory_test.ts — regression tests for UserActionFactory refund eligibility (#2131)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { withMockedFetch } from "../../../_test_utils/mock_http.ts";
import { UserActionFactory } from "./user_action_factory.ts";
import { UserActionRefund } from "../actions/user_action_refund.ts";
import type { TickConfig } from "../tick_types.ts";

const SUPABASE_URL = "https://test.supabase.co";
const TOKEN = "test-token";
const USER_ID = "user-test";

const config: TickConfig = { maxAppsPerUser: 5, negativeRate: 1.0, checkinRate: 0.0, usersPerTick: 1, minScheduledEvents: 0 };

function daysFromNow(days: number): string {
  const d = new Date();
  d.setTime(d.getTime() + days * 24 * 60 * 60 * 1000);
  return d.toISOString();
}

/** Feed + auth mock: returns empty event list (no new apply actions) */
function makeEmptyFeedMock(): typeof fetch {
  return (async (input: RequestInfo | URL): Promise<Response> => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
    if (url.includes("/auth/v1/token")) {
      return new Response(
        JSON.stringify({ access_token: "mock-jwt", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: { id: USER_ID } }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    if (url.includes("/functions/v1/user-event-feed")) {
      return new Response(
        JSON.stringify({ events: [] }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }
    throw new Error(`Unhandled fetch in test: ${url}`);
  }) as typeof fetch;
}

/** Builds a mock supabase client for a single approved+scheduled application. */
function buildApprovedAppMock(opts: { startTime: string; cutoffDays?: number }) {
  return createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({
          data: [{
            id: "app-1",
            event_id: "event-1",
            status: "approved",
            events: { status: "scheduled", start_time: opts.startTime },
          }],
          error: null,
        }),
      },
    },
    rpcs: {
      // Fix #2131: policy RPC instead of hardcoded cutoff
      get_current_policy: () => ({
        data: { cutoff_days: opts.cutoffDays ?? 7, grace_period_hours: 2 },
        error: null,
      }),
    },
  });
}

// ============================================================
// Regression tests: refund action generation (#2131)
// ============================================================

Deno.test({
  name: "UserActionFactory.generate - no refund action when event starts within 7-day cutoff (5 days away)",
  fn: async () => {
    const mock = buildApprovedAppMock({ startTime: daysFromNow(5) });
    const factory = new UserActionFactory(USER_ID, TOKEN, SUPABASE_URL, config);

    const actions = await withMockedFetch(makeEmptyFeedMock(), () =>
      factory.generate(mock as unknown as SupabaseClient)
    );

    // Fix #2131: event in 5 days < 7-day cutoff → refund action must not be generated
    const refundActions = actions.filter((a) => a instanceof UserActionRefund);
    assertEquals(refundActions.length, 0, "refund action must not be generated within cutoff window");
  },
});

Deno.test({
  name: "UserActionFactory.generate - refund action generated when event is beyond 7-day cutoff (10 days away)",
  fn: async () => {
    const mock = buildApprovedAppMock({ startTime: daysFromNow(10) });
    const factory = new UserActionFactory(USER_ID, TOKEN, SUPABASE_URL, config);

    const actions = await withMockedFetch(makeEmptyFeedMock(), () =>
      factory.generate(mock as unknown as SupabaseClient)
    );

    // negativeRate=1.0 → refund action must always be generated when eligible
    const refundActions = actions.filter((a) => a instanceof UserActionRefund);
    assertEquals(refundActions.length, 1, "refund action must be generated outside cutoff window");
  },
});

Deno.test({
  name: "UserActionFactory.generate - respects dynamic policy cutoffDays (custom 3-day cutoff)",
  fn: async () => {
    // custom 3-day cutoff: event in 4 days → eligible; event in 2 days → not eligible
    const mockEligible = buildApprovedAppMock({ startTime: daysFromNow(4), cutoffDays: 3 });
    const mockIneligible = buildApprovedAppMock({ startTime: daysFromNow(2), cutoffDays: 3 });
    const factory = new UserActionFactory(USER_ID, TOKEN, SUPABASE_URL, config);

    const actionsEligible = await withMockedFetch(makeEmptyFeedMock(), () =>
      factory.generate(mockEligible as unknown as SupabaseClient)
    );
    const actionsIneligible = await withMockedFetch(makeEmptyFeedMock(), () =>
      factory.generate(mockIneligible as unknown as SupabaseClient)
    );

    // Fix #2131: policy-driven cutoff; hardcoded 7d would give wrong results here
    assertEquals(actionsEligible.filter((a) => a instanceof UserActionRefund).length, 1);
    assertEquals(actionsIneligible.filter((a) => a instanceof UserActionRefund).length, 0);
  },
});
