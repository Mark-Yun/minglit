import { assertEquals } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simRefundRequests } from "./sim_refund.ts";
import { simCalcRefund } from "./sim_assertions.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};

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

Deno.test("simRefundRequests - 100% refund (event +30 days) → refund_amount == payment_amount", async () => {
  const paymentAmount = 10000;
  const startTime = daysFromNow(30);
  const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

  assertEquals(expectedCalc.refund_percentage, 100);
  assertEquals(expectedCalc.refund_amount, paymentAmount);

  const appStates: Record<string, { status: string; refund_status: string; refund_amount: number }> = {};
  const deletedParticipants: Array<{ event_id: string; user_id: string }> = [];

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const state = appStates[appId];
          if (state) {
            return {
              data: {
                id: appId,
                payment_amount: paymentAmount,
                event_id: "event-30d",
                user_id: "user-1",
                status: state.status,
                refund_status: state.refund_status,
                refund_amount: state.refund_amount,
              },
              error: null,
            };
          }
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              event_id: "event-30d",
              user_id: "user-1",
              status: "paid",
              refund_status: "none",
              refund_amount: 0,
            },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string; refund_status: string; refund_amount: number };
          appStates[appId] = { status: v.status, refund_status: v.refund_status, refund_amount: v.refund_amount };
          return { data: null, error: null };
        },
      },
      events: {
        select: () => ({
          data: { id: "event-30d", start_time: startTime },
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
    },
  });

  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-100pct"],
    noop,
    1.0,
  );

  assertEquals(result.refundedApplicationIds.length, 1);
  assertEquals(result.refundedApplicationIds[0], "app-100pct");
  assertEquals(appStates["app-100pct"].status, "cancelled");
  assertEquals(appStates["app-100pct"].refund_status, "completed");
  assertEquals(appStates["app-100pct"].refund_amount, paymentAmount);
  assertEquals(deletedParticipants.length, 1);
});

Deno.test("simRefundRequests - 0% refund (event +5 days, binary policy) → refund_amount=0", async () => {
  const paymentAmount = 10000;
  const startTime = daysFromNow(5);
  const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

  assertEquals(expectedCalc.refund_percentage, 0);
  assertEquals(expectedCalc.refund_amount, 0);

  const appStates: Record<string, { status: string; refund_status: string; refund_amount: number }> = {};

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const state = appStates[appId];
          if (state) {
            return {
              data: {
                id: appId,
                payment_amount: paymentAmount,
                event_id: "event-5d",
                user_id: "user-1",
                status: state.status,
                refund_status: state.refund_status,
                refund_amount: state.refund_amount,
              },
              error: null,
            };
          }
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              event_id: "event-5d",
              user_id: "user-1",
              status: "paid",
              refund_status: "none",
              refund_amount: 0,
            },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string; refund_status: string; refund_amount: number };
          appStates[appId] = { status: v.status, refund_status: v.refund_status, refund_amount: v.refund_amount };
          return { data: null, error: null };
        },
      },
      events: {
        select: () => ({
          data: { id: "event-5d", start_time: startTime },
          error: null,
        }),
      },
      event_participants: {
        delete: () => ({ data: null, error: null }),
      },
    },
  });

  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-80pct"],
    noop,
    1.0,
  );

  assertEquals(result.refundedApplicationIds.length, 0);
  assertEquals(appStates["app-80pct"].refund_status, "failed");
  assertEquals(appStates["app-80pct"].refund_amount, 0);
});

Deno.test("simRefundRequests - 0% refund (event +2 days, binary policy) → refund_amount=0", async () => {
  const paymentAmount = 9999;
  const startTime = daysFromNow(2);
  const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

  assertEquals(expectedCalc.refund_percentage, 0);
  assertEquals(expectedCalc.refund_amount, 0);

  const appStates: Record<string, { status: string; refund_status: string; refund_amount: number }> = {};

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const state = appStates[appId];
          if (state) {
            return {
              data: {
                id: appId,
                payment_amount: paymentAmount,
                event_id: "event-2d",
                user_id: "user-1",
                status: state.status,
                refund_status: state.refund_status,
                refund_amount: state.refund_amount,
              },
              error: null,
            };
          }
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              event_id: "event-2d",
              user_id: "user-1",
              status: "paid",
              refund_status: "none",
              refund_amount: 0,
            },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string; refund_status: string; refund_amount: number };
          appStates[appId] = { status: v.status, refund_status: v.refund_status, refund_amount: v.refund_amount };
          return { data: null, error: null };
        },
      },
      events: {
        select: () => ({
          data: { id: "event-2d", start_time: startTime },
          error: null,
        }),
      },
      event_participants: {
        delete: () => ({ data: null, error: null }),
      },
    },
  });

  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-50pct"],
    noop,
    1.0,
  );

  assertEquals(result.assertions.length, 1);
  assertEquals(appStates["app-50pct"].status, "cancelled");
  assertEquals(appStates["app-50pct"].refund_status, "failed");
  assertEquals(appStates["app-50pct"].refund_amount, 0);
});

Deno.test("simRefundRequests - 0% refund (+12 hours) → refund_amount=0, status='failed'", async () => {
  const paymentAmount = 10000;
  const startTime = hoursFromNow(12);
  const expectedCalc = simCalcRefund(new Date(startTime), paymentAmount, new Date());

  assertEquals(expectedCalc.refund_percentage, 0);
  assertEquals(expectedCalc.refund_amount, 0);

  const appStates: Record<string, { status: string; refund_status: string; refund_amount: number }> = {};
  const deletedParticipants: Array<{ event_id: string; user_id: string }> = [];

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const state = appStates[appId];
          if (state) {
            return {
              data: {
                id: appId,
                payment_amount: paymentAmount,
                event_id: "event-12h",
                user_id: "user-1",
                status: state.status,
                refund_status: state.refund_status,
                refund_amount: state.refund_amount,
              },
              error: null,
            };
          }
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              event_id: "event-12h",
              user_id: "user-1",
              status: "paid",
              refund_status: "none",
              refund_amount: 0,
            },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string; refund_status: string; refund_amount: number };
          appStates[appId] = { status: v.status, refund_status: v.refund_status, refund_amount: v.refund_amount };
          return { data: null, error: null };
        },
      },
      events: {
        select: () => ({
          data: { id: "event-12h", start_time: startTime },
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
    },
  });

  await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-0pct"],
    noop,
    1.0,
  );

  assertEquals(appStates["app-0pct"].status, "cancelled");
  assertEquals(appStates["app-0pct"].refund_status, "failed");
  assertEquals(appStates["app-0pct"].refund_amount, 0);
  assertEquals(deletedParticipants.length, 1);
});

Deno.test("simRefundRequests - participant is deleted when refund_percentage > 0", async () => {
  const paymentAmount = 5000;
  const startTime = daysFromNow(30);
  const deletedParticipants: Array<{ event_id: string; user_id: string }> = [];

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              event_id: "event-del",
              user_id: "user-del",
              status: "paid",
              refund_status: "none",
              refund_amount: 0,
            },
            error: null,
          };
        },
        update: () => ({ data: null, error: null }),
      },
      events: {
        select: () => ({
          data: { id: "event-del", start_time: startTime },
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
    },
  });

  await simRefundRequests(
    mock as unknown as SupabaseClient,
    ["app-del-1"],
    noop,
    1.0,
  );

  assertEquals(deletedParticipants.length, 1);
  assertEquals(deletedParticipants[0].event_id, "event-del");
  assertEquals(deletedParticipants[0].user_id, "user-del");
});

Deno.test("simRefundRequests - 20% of 5 apps → 1 refunded", async () => {
  const paymentAmount = 10000;
  const startTime = daysFromNow(30);
  const appIds = ["app-a", "app-b", "app-c", "app-d", "app-e"];
  const updatedApps: string[] = [];

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const wasUpdated = updatedApps.includes(appId);
          return {
            data: {
              id: appId,
              payment_amount: paymentAmount,
              event_id: "event-20pct",
              user_id: "user-1",
              status: wasUpdated ? "cancelled" : "paid",
              refund_status: wasUpdated ? "completed" : "none",
              refund_amount: wasUpdated ? paymentAmount : 0,
            },
            error: null,
          };
        },
        update: ({ filters }) => {
          const appId = filters["id"] as string;
          updatedApps.push(appId);
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
    },
  });

  const result = await simRefundRequests(
    mock as unknown as SupabaseClient,
    appIds,
    noop,
    0.2,
  );

  assertEquals(result.refundedApplicationIds.length, 1);
  assertEquals(updatedApps.length, 1);
  assertEquals(updatedApps[0], "app-a");
});
