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
 *   1. Fetch payment_amount + event_id from event_applications
 *   2. Fetch start_time from events
 *   3. Calculate refund using simCalcRefund()
 *   4. Update event_applications: status='cancelled', refund_status, refund_amount
 *   5. DELETE event_participants (triggers on_participant_change → decrements counts)
 *   6. Assert refund processed correctly
 */
export async function simRefundRequests(
  supabase: SupabaseClient,
  paidApplicationIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  refundRate: number = 0.2,
  supabaseUrl?: string,
  anonKey?: string,
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

    // Attempt to call payment-cancel EF with user token when credentials and payment_id are available
    let efSuccess = false;
    if (supabaseUrl && anonKey && paymentId) {
      // Look up user email from user_profiles
      const { data: profileData } = await supabase
        .from("user_profiles")
        .select("username")
        .eq("id", userId)
        .maybeSingle();
      const username = (profileData as { username?: string } | null)?.username;

      if (username && !username.startsWith("partner_")) {
        const userEmail = `${username}@test.com`;
        try {
          const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
          const efResult = await callEdgeFunction(supabaseUrl, "payment-cancel", {
            payment_id: paymentId,
            reason: "[E2E] 시뮬레이션 환불",
            amount: refundCalc.refund_amount > 0 ? refundCalc.refund_amount : undefined,
          }, userToken);

          if (efResult.status === 200) {
            efSuccess = true;
            log({
              level: "info",
              phase: "refund",
              step: "ef_cancel",
              message: `payment-cancel EF succeeded for app ${appId}`,
              data: { appId, paymentId, efStatus: efResult.status },
            });
          } else {
            log({
              level: "warn",
              phase: "refund",
              step: "ef_cancel_failed",
              message: `payment-cancel EF returned ${efResult.status} for app ${appId}, falling back to direct update`,
              data: { appId, efStatus: efResult.status },
            });
          }
        } catch (authErr) {
          log({
            level: "warn",
            phase: "refund",
            step: "ef_auth_fallback",
            message: `Auth failed for ${username}, using direct update: ${String(authErr)}`,
          });
        }
      }
    }

    if (!efSuccess) {
      // Fallback: direct DB update (used when EF call unavailable or failed)
      const refundStatus = refundCalc.refund_percentage > 0 ? "completed" : "failed";
      const { error: updateErr } = await supabase
        .from("event_applications")
        .update({
          status: "cancelled",
          refund_status: refundStatus,
          refund_amount: refundCalc.refund_amount,
        })
        .eq("id", appId);

      if (updateErr) {
        log({
          level: "error",
          phase: "refund",
          step: "update_app",
          message: `Failed to update app ${appId}: ${updateErr.message}`,
        });
        return null;
      }

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
          .update({ status: "paid", refund_status: null, refund_amount: null })
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
        message: `App ${appId} refunded: ${refundCalc.refund_percentage}% (${refundCalc.refund_amount}/${paymentAmount}) via ${efSuccess ? "EF" : "direct"}`,
        data: {
          appId,
          refund_percentage: refundCalc.refund_percentage,
          refund_amount: refundCalc.refund_amount,
          fee_amount: refundCalc.fee_amount,
          via_ef: efSuccess,
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
