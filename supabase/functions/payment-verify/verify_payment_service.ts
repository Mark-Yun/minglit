import type { EFContext } from "../_shared/edge_function.ts";
import type { IamportClient } from "../_shared/iamport_client.ts";
import type {
  PortoneV2Client,
  PortoneV2Payment,
} from "../_shared/portone_client.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { logStatsigEvent } from "../_shared/statsig_utils.ts";
import {
  evaluateGatewayPayment,
  isOrderOwner,
  isPaymentVerifyAlreadyProcessed,
  paidAtToIso,
  type PaymentVerificationOrderSnapshot,
} from "../_shared/domains/payment/payment_verification_policy.ts";
import type {
  PaymentVerifyAnyInput,
  PaymentVerifyInput,
  PaymentVerifyV2Input,
} from "./input.ts";

const FN = "payment-verify";

export type VerifyPaymentServiceResult =
  | { ok: true; alreadyProcessed: true; applicationId?: string }
  | {
    ok: true;
    alreadyProcessed: false;
    impUid?: string;
    paymentId?: string;
    applicationId: string;
  }
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
  input: PaymentVerifyAnyInput;
  iamportClient: Pick<IamportClient, "getPayment" | "cancelPayment">;
  portoneClient?: Pick<PortoneV2Client, "getPayment" | "cancelPayment">;
}): Promise<VerifyPaymentServiceResult> {
  if ("provider" in args.input) {
    if (!args.portoneClient) {
      return fail(500, "PortOne V2 client is not configured");
    }
    return verifyPortoneV2Payment({
      supabase: args.supabase,
      userId: args.userId,
      input: args.input,
      portoneClient: args.portoneClient,
    });
  }

  return verifyIamportV1Payment(
    args as {
      supabase: EFContext["supabase"];
      userId: string;
      input: PaymentVerifyInput;
      iamportClient: Pick<IamportClient, "getPayment" | "cancelPayment">;
    },
  );
}

async function verifyIamportV1Payment(args: {
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
        .select("id, payment_amount, status, user_id")
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
    return {
      ok: true,
      alreadyProcessed: true,
      applicationId: input.merchant_uid,
    };
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

  return {
    ok: true,
    alreadyProcessed: false,
    impUid: input.imp_uid,
    applicationId: input.merchant_uid,
  };
}

async function verifyPortoneV2Payment(args: {
  supabase: EFContext["supabase"];
  userId: string;
  input: PaymentVerifyV2Input;
  portoneClient: Pick<PortoneV2Client, "getPayment" | "cancelPayment">;
}): Promise<VerifyPaymentServiceResult> {
  const { supabase, userId, input, portoneClient } = args;

  const { data: order, error: orderError } = await withSpan(
    "db.query.event_applications.v2",
    "db.query",
    () =>
      supabase
        .from("event_applications")
        .select("id, payment_amount, status, user_id")
        .eq("payment_id", input.payment_id)
        .eq("user_id", userId)
        .single(),
  );

  if (orderError || !order) {
    return fail(404, "Order not found");
  }

  const typedOrder = order as PaymentVerificationOrderSnapshot & { id: string };
  if (isPaymentVerifyAlreadyProcessed(typedOrder.status)) {
    return { ok: true, alreadyProcessed: true, applicationId: typedOrder.id };
  }

  const payment = await portoneClient.getPayment(input.payment_id);
  const normalizedPayment = normalizePortoneV2Payment(payment);
  const paymentPolicy = evaluateGatewayPayment(
    normalizedPayment,
    typedOrder.payment_amount,
  );

  if (!paymentPolicy.ok) {
    if (paymentPolicy.reason === "amount_mismatch") {
      await portoneClient
        .cancelPayment(input.payment_id, "결제 금액 위변조로 자동 취소")
        .catch((error: unknown) => {
          const message = error instanceof Error
            ? error.message
            : String(error);
          log({
            function: FN,
            level: "error",
            message: "PortOne V2 cancel on mismatch failed",
            metadata: { detail: message },
          });
        });
    }

    logStatsigEvent(userId, "payment_failed", undefined, {
      reason: paymentPolicy.reason,
      payment_id: input.payment_id,
      provider: "portone_v2",
    }).catch(() => {});

    return fail(
      paymentPolicy.status,
      paymentPolicy.message,
      paymentPolicy.details,
    );
  }

  const { error: updateError } = await withSpan(
    "db.update.event_applications.v2",
    "db.update",
    () =>
      supabase
        .from("event_applications")
        .update({
          status: "approved",
          payment_id: input.payment_id,
          ...(normalizedPayment.paid_at
            ? { paid_at: normalizedPayment.paid_at }
            : {}),
          updated_at: new Date().toISOString(),
        })
        .eq("id", typedOrder.id),
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
      payment_id: input.payment_id,
      provider: "portone_v2",
    }).catch(() => {});
    return fail(500, "Failed to update order status");
  }

  logStatsigEvent(userId, "payment_completed", normalizedPayment.amount, {
    payment_id: input.payment_id,
    provider: "portone_v2",
  }).catch(() => {});

  return {
    ok: true,
    alreadyProcessed: false,
    paymentId: input.payment_id,
    applicationId: typedOrder.id,
  };
}

function normalizePortoneV2Payment(
  payment: PortoneV2Payment,
): { status: string; amount: number; paid_at: string | null } {
  const rawStatus = String(payment.status ?? "").toLowerCase();
  const amount = typeof payment.amount === "number"
    ? payment.amount
    : typeof payment.amount?.total === "number"
    ? payment.amount.total
    : NaN;
  const paidAt = typeof payment.paidAt === "string"
    ? payment.paidAt
    : typeof payment.paid_at === "string"
    ? payment.paid_at
    : null;
  return {
    status: rawStatus,
    amount,
    paid_at: paidAt,
  };
}

function fail(
  status: number,
  message: string,
  details?: unknown,
): VerifyPaymentServiceFailure {
  return { ok: false, status, message, details };
}
