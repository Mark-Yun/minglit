import type { EFContext } from "../_shared/edge_function.ts";
import type { IamportClient } from "../_shared/iamport_client.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { logStatsigEvent } from "../_shared/statsig_utils.ts";
import {
  evaluateGatewayPayment,
  isOrderOwner,
  isPaymentVerifyAlreadyProcessed,
  paidAtToIso,
  type PaymentVerificationOrderSnapshot,
} from "../_shared/domains/payment/payment_verification_policy.ts";
import type { PaymentVerifyInput } from "./input.ts";

const FN = "payment-verify";

export type VerifyPaymentServiceResult =
  | { ok: true; alreadyProcessed: true }
  | { ok: true; alreadyProcessed: false; impUid: string }
  | VerifyPaymentServiceFailure;

export interface VerifyPaymentServiceFailure {
  ok: false;
  status: number;
  message: string;
  details?: unknown;
}

export async function verifyPayment(args: {
  supabase: EFContext["supabase"];
  userId: string;
  input: PaymentVerifyInput;
  iamportClient: Pick<IamportClient, "getPayment" | "cancelPayment">;
}): Promise<VerifyPaymentServiceResult> {
  const { supabase, userId, input, iamportClient } = args;

  const { data: order, error: orderError } = await withSpan(
    "db.query.event_applications",
    "db.query",
    () =>
      supabase
        .from("event_applications")
        .select("payment_amount, status, user_id")
        .eq("id", input.merchant_uid)
        .single(),
  );

  if (orderError || !order) {
    return fail(404, "Order not found");
  }

  const typedOrder = order as PaymentVerificationOrderSnapshot;
  if (!isOrderOwner(typedOrder, userId)) {
    return fail(403, "Forbidden");
  }

  if (isPaymentVerifyAlreadyProcessed(typedOrder.status)) {
    return { ok: true, alreadyProcessed: true };
  }

  const payment = await iamportClient.getPayment(input.imp_uid);
  const paymentPolicy = evaluateGatewayPayment(
    payment,
    typedOrder.payment_amount,
  );

  if (!paymentPolicy.ok) {
    if (paymentPolicy.reason === "amount_mismatch") {
      await iamportClient
        .cancelPayment(input.imp_uid, "결제 금액 위변조로 자동 취소")
        .catch((error: unknown) => {
          const message = error instanceof Error
            ? error.message
            : String(error);
          log({
            function: FN,
            level: "error",
            message: "Cancel on mismatch failed",
            metadata: { detail: message },
          });
        });
    }

    logStatsigEvent(userId, "payment_failed", undefined, {
      reason: paymentPolicy.reason,
      imp_uid: input.imp_uid,
    }).catch(() => {});

    return fail(
      paymentPolicy.status,
      paymentPolicy.message,
      paymentPolicy.details,
    );
  }

  const paidAtIso = paidAtToIso(payment.paid_at);
  const { error: updateError } = await withSpan(
    "db.update.event_applications",
    "db.update",
    () =>
      supabase
        .from("event_applications")
        .update({
          status: "approved",
          payment_id: input.imp_uid,
          ...(paidAtIso ? { paid_at: paidAtIso } : {}),
          updated_at: new Date().toISOString(),
        })
        .eq("id", input.merchant_uid),
  );

  if (updateError) {
    log({
      function: FN,
      level: "error",
      message: "DB Update Error",
      metadata: { detail: updateError },
    });
    logStatsigEvent(userId, "payment_failed", undefined, {
      reason: "db_update_error",
      imp_uid: input.imp_uid,
    }).catch(() => {});
    return fail(500, "Failed to update order status");
  }

  logStatsigEvent(userId, "payment_completed", payment.amount, {
    imp_uid: input.imp_uid,
    merchant_uid: input.merchant_uid,
  }).catch(() => {});

  return { ok: true, alreadyProcessed: false, impUid: input.imp_uid };
}

function fail(
  status: number,
  message: string,
  details?: unknown,
): VerifyPaymentServiceFailure {
  return { ok: false, status, message, details };
}
