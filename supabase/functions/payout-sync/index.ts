// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "../_shared/supabase_client.ts";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireServiceRole } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "payout-sync";

const PORTONE_V2_API_KEY = Deno.env.get("PORTONE_V2_API_KEY");

if (!PORTONE_V2_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

initSentry();

const NON_RETRYABLE_ERRORS = new Set([
  "INVALID_BANK_ACCOUNT",
  "ACCOUNT_CLOSED",
  "NAME_MISMATCH",
  "COMPLIANCE_REVIEW_REQUIRED",
]);

const RETRYABLE_ERRORS = new Set([
  "BANK_API_TIMEOUT",
  "BANK_API_5XX",
  "NETWORK_ERROR",
  "PROVIDER_RATE_LIMIT",
]);

function classifyError(errorCode: string): { retryable: boolean } {
  if (NON_RETRYABLE_ERRORS.has(errorCode)) return { retryable: false };
  if (RETRYABLE_ERRORS.has(errorCode)) return { retryable: true };
  return { retryable: true };
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  // Fix #593: service_role 전용으로 전환 — 벌크 금융 작업에 일반 유저 접근 차단
  const auth = requireServiceRole(req);
  if (auth instanceof Response) return auth;

  try {
    const supabase = createServiceClient();

    const { data: activePayout, error: payoutFetchError } = await supabase
      .from("payouts")
      .select("id, partner_id, status, item_count")
      .in("status", ["CREATED", "READY", "PROCESSING"]);

    if (payoutFetchError) {
      log({ function: FN, level: "error", message: `Failed to fetch active payouts: ${payoutFetchError.message}` });
      return errorResponse("Failed to fetch payouts", 500);
    }

    if (!activePayout || activePayout.length === 0) {
      return successResponse({ synced: 0 });
    }

    const portone = new PortoneV2Client(PORTONE_V2_API_KEY);
    let synced = 0;

    for (const payout of activePayout) {
      try {
        const { data: partner, error: partnerError } = await supabase
          .from("partners")
          .select("portone_partner_id")
          .eq("id", payout.partner_id)
          .single();

        if (partnerError || !partner?.portone_partner_id) {
          log({ function: FN, level: "error", message: `Partner not found for payout ${payout.id}` });
          continue;
        }

        let portonePayouts: { id?: string; status?: string; [key: string]: unknown }[] = [];
        try {
          const result = await portone.getPayouts({ partnerId: partner.portone_partner_id });
          portonePayouts = result.payouts ?? [];
        } catch (e) {
          const message = e instanceof Error ? e.message : String(e);
          log({ function: FN, level: "error", message: `getPayouts failed for payout ${payout.id}: ${message}` });
          continue;
        }

        const matchedPortonePayout = portonePayouts.find(
          (p) => p.partnerId === partner.portone_partner_id,
        );

        if (!matchedPortonePayout) {
          continue;
        }

        const portoneStatus = (matchedPortonePayout.status as string | undefined) ?? "";
        const portonePayoutId = matchedPortonePayout.id as string | undefined;

        const { data: existingTransfers } = await supabase
          .from("payout_transfers")
          .select("attempt_no")
          .eq("payout_id", payout.id)
          .order("attempt_no", { ascending: false })
          .limit(1);

        const attemptNo = (existingTransfers?.[0]?.attempt_no ?? 0) + 1;
        const env = "prod";
        const idempotencyKey = `${env}:transfer:${payout.id}:${attemptNo}`;

        if (portoneStatus === "PAID" || portoneStatus === "COMPLETED") {
          const { data: linkedItems } = await supabase
            .from("settlement_items")
            .select("id, version")
            .eq("payout_id", payout.id)
            .eq("status", "PROCESSING");

           for (const item of linkedItems ?? []) {
             await supabase.rpc("transition_settlement_status", {
               p_item_id: item.id,
               p_expected_version: item.version,
               p_new_status: "SUCCEEDED",
               p_actor_type: "SYSTEM",
               p_actor_id: "payout_sync",
               p_event_type: "payout_completed",
               p_hold_reason_code: null,
               p_hold_reason_detail: null,
               p_failure_reason_code: null,
               p_failure_message: null,
               p_details: { source: "payout_sync", portone_payout_id: portonePayoutId },
               p_idempotency_key: null,
             });
           }

           await supabase.from("payout_transfers").insert({
             payout_id: payout.id,
             provider: "portone",
             idempotency_key: idempotencyKey,
             attempt_no: attemptNo,
             status: "SUCCEEDED",
             retryable: false,
             response_payload: matchedPortonePayout,
           });

          synced++;
        } else if (portoneStatus === "FAILED" || portoneStatus === "CANCELED") {
          const errorCode = (matchedPortonePayout.failureCode as string | undefined) ?? "UNKNOWN";
          const { retryable } = classifyError(errorCode);

          const { data: linkedItems } = await supabase
            .from("settlement_items")
            .select("id, version, retry_count")
            .eq("payout_id", payout.id)
            .eq("status", "PROCESSING");

          for (const item of linkedItems ?? []) {
            const newRetryCount = item.retry_count + 1;
            const shouldHold = !retryable || newRetryCount >= 8;
            const newStatus = shouldHold ? "HOLD" : "FAILED";

            await supabase.rpc("transition_settlement_status", {
              p_item_id: item.id,
              p_expected_version: item.version,
              p_new_status: newStatus,
              p_actor_type: "SYSTEM",
              p_actor_id: "payout_sync",
              p_event_type: shouldHold ? "hold_applied" : "payout_failed",
              p_hold_reason_code: shouldHold ? (retryable ? "MAX_RETRY_EXCEEDED" : errorCode) : null,
              p_hold_reason_detail: shouldHold ? `error_class: ${errorCode}` : null,
              p_failure_reason_code: shouldHold ? null : errorCode,
              p_failure_message: shouldHold ? null : `PortOne payout failed: ${errorCode}`,
              p_details: { source: "payout_sync", error_code: errorCode, retryable },
              p_idempotency_key: null,
            });

            if (!shouldHold) {
              const { data: nextRetryAt } = await supabase.rpc("calculate_next_retry_at", {
                p_retry_count: newRetryCount,
              });

              await supabase
                .from("settlement_items")
                .update({ retry_count: newRetryCount, next_retry_at: nextRetryAt })
                .eq("id", item.id);
            }
          }

          await supabase.from("payout_transfers").insert({
            payout_id: payout.id,
            provider: "portone",
            idempotency_key: idempotencyKey,
            attempt_no: attemptNo,
            status: "FAILED",
            retryable,
            response_payload: matchedPortonePayout,
          });

          synced++;
        }
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        log({ function: FN, level: "error", message: `Error syncing payout ${payout.id}: ${message}` });
      }
    }

    return successResponse({ synced });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: `Error in payout-sync: ${message}` });
    return errorResponse(message, 500);
  }
}));
