// sim_refund.ts — Phase 4: Refund Request Simulation

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import { simCalcRefund, simAssertRefundProcessed } from "./sim_assertions.ts";

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

  for (const appId of toRefund) {
    try {
      const { data: appData, error: appErr } = await supabase
        .from("event_applications")
        .select("payment_amount, event_id, user_id")
        .eq("id", appId)
        .single();

      if (appErr || !appData) {
        log({
          level: "warn",
          phase: "refund",
          step: "fetch_app",
          message: `App ${appId} not found or error: ${appErr?.message ?? "null data"}`,
        });
        continue;
      }

      // deno-lint-ignore no-explicit-any
      const app = appData as any;
      const paymentAmount: number = app.payment_amount ?? 0;
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
        continue;
      }

      // deno-lint-ignore no-explicit-any
      const ev = eventData as any;
      const startTime = new Date(ev.start_time);

      const refundCalc = simCalcRefund(startTime, paymentAmount, new Date());

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
        continue;
      }

      const { error: deleteErr } = await supabase
        .from("event_participants")
        .delete()
        .eq("event_id", eventId)
        .eq("user_id", userId);

      if (deleteErr) {
        log({
          level: "warn",
          phase: "refund",
          step: "delete_participant",
          message: `Failed to delete participant for app ${appId}: ${deleteErr.message}`,
        });
      }

      const assertion = await simAssertRefundProcessed(
        supabase,
        appId,
        refundCalc.refund_amount,
        refundCalc.refund_percentage,
      );
      assertions.push(assertion);

      if (assertion.passed) {
        refundedApplicationIds.push(appId);
        log({
          level: "info",
          phase: "refund",
          step: "refunded",
          message: `App ${appId} refunded: ${refundCalc.refund_percentage}% (${refundCalc.refund_amount}/${paymentAmount})`,
          data: {
            appId,
            refund_percentage: refundCalc.refund_percentage,
            refund_amount: refundCalc.refund_amount,
            fee_amount: refundCalc.fee_amount,
            refund_status: refundStatus,
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
    } catch (e) {
      log({
        level: "error",
        phase: "refund",
        step: "refund_loop",
        message: `Unexpected error for app ${appId}: ${String(e)}`,
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
