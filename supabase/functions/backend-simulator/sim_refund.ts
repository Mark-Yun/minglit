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
 *   1. Fetch payment_amount + payment_id + event_id + user_id from event_applications
 *   2. Fetch start_time from events
 *   3. Calculate refund using simCalcRefund()
 *   4. Call payment-cancel EF (the only refund path — no direct DB fallback)
 *   5. Update event_applications: status='cancelled' (EF sets refund_status/refund_amount)
 *   6. DELETE event_participants (no DB trigger handles this on refund)
 *   7. Assert refund processed correctly
 *
 * Fix #1280: Remove direct DB fallback for refund. payment-cancel EF is now the sole
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

    // Fix #1280: payment-cancel EF is the only refund path. No direct DB fallback.
    // Missing credentials or payment_id → throw immediately.
    if (!supabaseUrl || !anonKey) {
      throw new Error(`App ${appId}: supabaseUrl/anonKey required for payment-cancel EF`);
    }

    if (!paymentId) {
      throw new Error(`App ${appId}: payment_id is null, cannot call payment-cancel EF`);
    }

    // Look up user email from user_profiles
    const { data: profileData } = await supabase
      .from("user_profiles")
      .select("username")
      .eq("id", userId)
      .maybeSingle();
    const username = (profileData as { username?: string } | null)?.username;

    if (!username || username.startsWith("partner_")) {
      throw new Error(`App ${appId}: no valid user username (got: ${username ?? "null"}), cannot call payment-cancel EF`);
    }

    const userEmail = `${username}@test.com`;
    const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
    const efResult = await callEdgeFunction(supabaseUrl, "payment-cancel", {
      payment_id: paymentId,
      reason: "[E2E] 시뮬레이션 환불",
      amount: refundCalc.refund_amount > 0 ? refundCalc.refund_amount : undefined,
    }, userToken);

    if (efResult.status !== 200) {
      throw new Error(`App ${appId}: payment-cancel EF returned ${efResult.status}`);
    }

    log({
      level: "info",
      phase: "refund",
      step: "ef_cancel",
      message: `payment-cancel EF succeeded for app ${appId}`,
      data: { appId, paymentId, efStatus: efResult.status },
    });

    // EF sets refund_status and refund_amount. Update status='cancelled' separately,
    // since payment-cancel EF does not touch the status field.
    const { error: updateErr } = await supabase
      .from("event_applications")
      .update({ status: "cancelled" })
      .eq("id", appId);

    if (updateErr) {
      log({
        level: "error",
        phase: "refund",
        step: "update_app_status",
        message: `Failed to set status=cancelled for app ${appId}: ${updateErr.message}`,
      });
      return null;
    }

    // Delete participant. No DB trigger handles this on refund — must be done explicitly.
    const { error: deleteErr } = await supabase
      .from("event_participants")
      .delete()
      .eq("event_id", eventId)
      .eq("user_id", userId);

    if (deleteErr) {
      // Rollback: participant delete failed — revert application status to avoid cancelled-but-has-participant state
      // Fix #507: capture rollback error to avoid masking failures
      const { error: rollbackErr } = await supabase
        .from("event_applications")
        .update({ status: "paid" })
        .eq("id", appId);
      log({
        level: "error",
        phase: "refund",
        step: rollbackErr ? "rollback_app_failed" : "delete_participant",
        message: rollbackErr
          ? `Participant delete failed and rollback also failed for app ${appId}: ${deleteErr.message}; rollback error: ${rollbackErr.message}`
          : `Participant delete failed, reverted application ${appId}: ${deleteErr.message}`,
      });
      return null;
    }

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
