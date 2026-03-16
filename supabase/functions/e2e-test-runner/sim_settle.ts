// sim_settle.ts — Phase 6: Settlement Verification + Ready Transition

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import {
  simAssertSettlementCreated,
  simAssertSettlementAmounts,
  simAssertSettlementReady,
  simAssertSettlementChecksum,
} from "./sim_assertions.ts";

export interface SimSettleResult {
  settlementIds: string[];
  assertions: SimAssertionResult[];
}

// ─────────────────────────────────────────────────────────
// simVerifySettlement
// ─────────────────────────────────────────────────────────

/**
 * Verifies that settlement_items rows were created for each completed event.
 * For each eventId:
 *   1. Assert settlement_items has PENDING row (simAssertSettlementCreated)
 *   2. Query settlement_items to get gross_amount and id
 *   3. Assert fee calculations are correct (simAssertSettlementAmounts)
 *   4. Assert calc_checksum is 64-char hex (simAssertSettlementChecksum)
 */
export async function simVerifySettlement(
  supabase: SupabaseClient,
  completedEventIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
): Promise<SimSettleResult> {
  const settlementIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  if (completedEventIds.length === 0) {
    log({ level: "info", phase: "settle", step: "skip", message: "No completed events to verify" });
    return { settlementIds, assertions };
  }

  for (const eventId of completedEventIds) {
    try {
      // 1. Assert settlement_items has PENDING row
      const createdAssertion = await simAssertSettlementCreated(supabase, eventId);
      assertions.push(createdAssertion);

      if (!createdAssertion.passed) {
        log({
          level: "warn",
          phase: "settle",
          step: "settlement_missing",
          message: `No PENDING settlement for event ${eventId}: ${createdAssertion.details}`,
        });
        continue;
      }

      // 2. Query settlement_items to get id and gross_amount
      const { data: settlement, error: fetchErr } = await supabase
        .from("settlement_items")
        .select("id, status, gross_amount")
        .eq("source_id", eventId)
        .eq("source_type", "EVENT")
        .maybeSingle();

      if (fetchErr || !settlement) {
        log({
          level: "error",
          phase: "settle",
          step: "fetch_settlement",
          message: `Failed to fetch settlement for event ${eventId}: ${fetchErr?.message ?? "no row"}`,
        });
        continue;
      }

      const settlementId = (settlement as { id: string; status: string; gross_amount: number }).id;
      const grossAmount = (settlement as { id: string; status: string; gross_amount: number }).gross_amount;

      // 3. Assert fee calculations
      const amountsAssertion = await simAssertSettlementAmounts(supabase, settlementId, grossAmount);
      assertions.push(amountsAssertion);

      // 4. Assert checksum
      const checksumAssertion = await simAssertSettlementChecksum(supabase, settlementId);
      assertions.push(checksumAssertion);

      if (createdAssertion.passed) {
        settlementIds.push(settlementId);
      }

      log({
        level: "info",
        phase: "settle",
        step: "verified",
        message: `Settlement verified for event ${eventId}: id=${settlementId}, gross=${grossAmount}`,
        data: { eventId, settlementId, grossAmount },
      });
    } catch (e) {
      log({
        level: "error",
        phase: "settle",
        step: "verify_loop",
        message: `Unexpected error for event ${eventId}: ${String(e)}`,
      });
    }
  }

  log({
    level: "info",
    phase: "settle",
    step: "complete",
    message: `Phase 6 verify complete: ${settlementIds.length} settlements verified`,
    data: { settlementCount: settlementIds.length },
  });

  return { settlementIds, assertions };
}

// ─────────────────────────────────────────────────────────
// simTransitionToReady
// ─────────────────────────────────────────────────────────

/**
 * Transitions settlement_items from PENDING → READY by:
 *   1. UPDATE settlement_items SET event_completed_at = now() - 15 days (makes eligible)
 *   2. Call update_settlement_ready_status() via RPC
 *   3. Assert settlement is now READY (simAssertSettlementReady)
 */
export async function simTransitionToReady(
  supabase: SupabaseClient,
  settlementIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
): Promise<{ readyIds: string[]; assertions: SimAssertionResult[] }> {
  const readyIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  if (settlementIds.length === 0) {
    log({ level: "info", phase: "settle_ready", step: "skip", message: "No settlements to transition" });
    return { readyIds, assertions };
  }

  for (const settlementId of settlementIds) {
    try {
      // 1. Set event_completed_at to 15 days ago (makes it eligible for READY transition)
      const fifteenDaysAgo = new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString();
      const { error: updErr } = await supabase
        .from("settlement_items")
        .update({ event_completed_at: fifteenDaysAgo })
        .eq("id", settlementId);

      if (updErr) {
        log({
          level: "error",
          phase: "settle_ready",
          step: "update_completed_at",
          message: `Failed to update event_completed_at for settlement ${settlementId}: ${updErr.message}`,
        });
        continue;
      }

      // 2. Call update_settlement_ready_status() to transition PENDING → READY
      const { error: rpcErr } = await supabase.rpc("update_settlement_ready_status");

      if (rpcErr) {
        log({
          level: "error",
          phase: "settle_ready",
          step: "rpc_ready_status",
          message: `RPC update_settlement_ready_status failed for settlement ${settlementId}: ${rpcErr.message}`,
        });
        continue;
      }

      // 3. Assert settlement is now READY
      const readyAssertion = await simAssertSettlementReady(supabase, settlementId);
      assertions.push(readyAssertion);

      if (readyAssertion.passed) {
        readyIds.push(settlementId);
        log({
          level: "info",
          phase: "settle_ready",
          step: "transitioned",
          message: `Settlement ${settlementId} transitioned to READY`,
          data: { settlementId },
        });
      } else {
        log({
          level: "warn",
          phase: "settle_ready",
          step: "still_pending",
          message: `Settlement ${settlementId} still not READY: ${readyAssertion.details}`,
        });
      }
    } catch (e) {
      log({
        level: "error",
        phase: "settle_ready",
        step: "transition_loop",
        message: `Unexpected error for settlement ${settlementId}: ${String(e)}`,
      });
    }
  }

  log({
    level: "info",
    phase: "settle_ready",
    step: "complete",
    message: `Phase 6 ready transition complete: ${readyIds.length}/${settlementIds.length} transitioned`,
    data: { readyCount: readyIds.length, totalCount: settlementIds.length },
  });

  return { readyIds, assertions };
}
