// sim_refund.ts — Phase 4: Refund Request Simulation

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import { simCalcRefund, simAssertRefundProcessed } from "./sim_assertions.ts";
import { getSimUserToken, callEdgeFunction } from "./sim_auth.ts";

export interface SimRefundResult {
  refundedApplicationIds: string[];
  assertions: SimAssertionResult[];
}

/**
 * Simulates refund requests for a subset of paid applications.
 *
 * For each selected application:
 *   1. Fetch payment_amount + event_id + user_id from event_applications
 *   2. Fetch start_time from events
 *   3. Calculate refund using simCalcRefund()
 *   4. Call user-cancel-order EF (handles cancellation, refund, and participant cleanup atomically)
 *   5. Assert refund processed correctly
 *
 * Fix #1327: Replace payment-cancel EF + direct DB with user-cancel-order EF as the sole
 * refund path. EF failure throws regardless of strict mode.
 */
export async function simRefundRequests(
  supabase: SupabaseClient,
  paidApplicationIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  refundRate: number = 0.2,
  supabaseUrl?: string,
  anonKey?: string,
  _strict?: boolean,
): Promise<SimRefundResult> {
  const refundedApplicationIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  if (paidApplicationIds.length === 0) {
    log({ level: "info", phase: "refund", step: "skip", message: "No paid applications to process" });
    return { refundedApplicationIds, assertions };
  }

  const refundCount = Math.floor(paidApplicationIds.length * refundRate);
  if (refundCount === 0) {
    log({
      level: "info",
      phase: "refund",
      step: "skip",
      message: `refundRate=${refundRate} → 0 applications selected for refund`,
    });
    return { refundedApplicationIds, assertions };
  }

  const toRefund = paidApplicationIds.slice(0, refundCount);

  log({
    level: "info",
    phase: "refund",
    step: "start",
    message: `Processing ${toRefund.length} refund(s) out of ${paidApplicationIds.length} paid applications`,
    data: { refundCount: toRefund.length, totalPaid: paidApplicationIds.length, refundRate },
  });

  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";

  // Fix #507: Process refunds in parallel to prevent curl 120s timeout.
  // Previously sequential processing caused N * (DB queries + EF call) ≈ 120s+.
  const results = await Promise.allSettled(toRefund.map(async (appId) => {
    const { data: appData, error: appErr } = await supabase
      .from("event_applications")
      .select("payment_amount, payment_id, event_id, user_id")
      .eq("id", appId)
      .single();

    if (appErr || !appData) {
      log({
        level: "warn",
        phase: "refund",
        step: "fetch_app",
        message: `App ${appId} not found or error: ${appErr?.message ?? "null data"}`,
      });
      return null;
    }

    // deno-lint-ignore no-explicit-any
    const app = appData as any;
    const paymentAmount: number = app.payment_amount ?? 0;
    const paymentId: string | null = app.payment_id ?? null;
    const eventId: string = app.event_id;
    const userId: string = app.user_id;

    const { data: eventData, error: eventErr } = await supabase
      .from("events")
      .select("start_time")
      .eq("id", eventId)
      .single();

    if (eventErr || !eventData) {
      log({
        level: "warn",
        phase: "refund",
        step: "fetch_event",
        message: `Event ${eventId} not found or error: ${eventErr?.message ?? "null data"}`,
      });
      return null;
    }

    // deno-lint-ignore no-explicit-any
    const ev = eventData as any;
    const startTime = new Date(ev.start_time);

    const refundCalc = simCalcRefund(startTime, paymentAmount, new Date(), null, 2, 7);

    // Fix #1327: user-cancel-order EF로 전환 — payment-cancel 사용 중단 + direct DB 제거
    // user-cancel-order EF handles cancellation, refund, participant cleanup atomically.
    if (!supabaseUrl || !anonKey) {
      throw new Error(`App ${appId}: supabaseUrl/anonKey required for user-cancel-order EF`);
    }

    // Look up user email from user_profiles
    const { data: profileData } = await supabase
      .from("user_profiles")
      .select("username")
      .eq("id", userId)
      .maybeSingle();
    const username = (profileData as { username?: string } | null)?.username;

    if (!username || username.startsWith("partner_")) {
      throw new Error(`App ${appId}: no valid user username (got: ${username ?? "null"}), cannot call user-cancel-order EF`);
    }

    const userEmail = `${username}@test.com`;
    const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
    const efResult = await callEdgeFunction(supabaseUrl, "user-cancel-order", {
      event_id: eventId,
    }, userToken);

    if (efResult.status !== 200) {
      throw new Error(`user-cancel-order EF returned ${efResult.status} for app ${appId}`);
    }

    log({
      level: "info",
      phase: "refund",
      step: "ef_cancel",
      message: `user-cancel-order EF succeeded for app ${appId}`,
      data: { appId, eventId, efStatus: efResult.status },
    });

    const assertion = await simAssertRefundProcessed(
      supabase,
      appId,
      refundCalc.refund_amount,
      refundCalc.refund_percentage,
    );

    if (assertion.passed) {
      log({
        level: "info",
        phase: "refund",
        step: "refunded",
        message: `App ${appId} refunded: ${refundCalc.refund_percentage}% (${refundCalc.refund_amount}/${paymentAmount}) via EF`,
        data: {
          appId,
          refund_percentage: refundCalc.refund_percentage,
          refund_amount: refundCalc.refund_amount,
          fee_amount: refundCalc.fee_amount,
          via_ef: true,
        },
      });
    } else {
      log({
        level: "warn",
        phase: "refund",
        step: "assert_failed",
        message: `Refund assertion failed for app ${appId}: ${assertion.details}`,
      });
    }

    return { appId, assertion };
  }));

  for (const result of results) {
    if (result.status === "fulfilled" && result.value) {
      assertions.push(result.value.assertion);
      if (result.value.assertion.passed) {
        refundedApplicationIds.push(result.value.appId);
      }
    } else if (result.status === "rejected") {
      log({
        level: "error",
        phase: "refund",
        step: "refund_loop",
        message: `Unexpected error: ${String(result.reason)}`,
      });
    }
  }

  log({
    level: "info",
    phase: "refund",
    step: "done",
    message: `Phase 4 complete: ${refundedApplicationIds.length} refunded`,
    data: { refundedCount: refundedApplicationIds.length },
  });

  return { refundedApplicationIds, assertions };
}
