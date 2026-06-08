import type { EFContext } from "../_shared/edge_function.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { executeRefund, RefundError } from "../_shared/refund_utils.ts";
import { logStatsigEvent } from "../_shared/statsig_utils.ts";
import {
  parseRefundPolicy,
  verifyRefundEligibility,
} from "../_shared/domains/payment/refund_policy.ts";
import {
  type CancelOrderApplicationSnapshot,
  decideCancelOrderPath,
  evaluateFreeCancellationWindow,
} from "../_shared/domains/payment/cancel_order_policy.ts";
import type { CancelOrderInput } from "./input.ts";

const FN = "user-cancel-order";

export type CancelOrderServiceResult =
  | { ok: true; type: "cancelled" }
  | { ok: true; type: "refunded"; refundAmount: number | undefined }
  | {
    ok: true;
    type: "partner_refund_available";
    applicationId: string;
    reason: string;
    deadlineHours: number;
  }
  | { ok: false; status: number; message: string; details?: unknown };

export async function cancelOrder(args: {
  supabase: EFContext["supabase"];
  userId: string;
  input: CancelOrderInput;
  now?: Date;
}): Promise<CancelOrderServiceResult> {
  const { supabase, userId, input } = args;
  const now = args.now ?? new Date();

  const { data: application, error: appError } = await withSpan(
    "db.query.event_applications",
    "db.query",
    () =>
      supabase
        .from("event_applications")
        .select(
          "id, status, payment_id, payment_amount, paid_at, refund_status, event_id, user_id",
        )
        .eq("event_id", input.event_id)
        .eq("user_id", userId)
        .single(),
  );

  if (appError || !application) {
    return fail(404, "해당 이벤트에 신청 내역이 없습니다");
  }

  const typedApplication = application as CancelOrderApplicationSnapshot & {
    id: string;
    payment_id: string | null;
    paid_at: string | null;
  };
  const path = decideCancelOrderPath(typedApplication);

  if (!path.ok) {
    if (path.message === "결제 정보가 손상된 신청입니다") {
      log({
        function: FN,
        level: "error",
        message: "Damaged data: payment_amount=null on paid application",
        metadata: { application_id: typedApplication.id },
      });
    } else if (path.message === "지원하지 않는 신청 상태입니다") {
      log({
        function: FN,
        level: "error",
        message: `Unhandled status: ${typedApplication.status}`,
        metadata: { application_id: typedApplication.id },
      });
    }
    return fail(path.status, path.message, path.details);
  }

  if (path.type === "pre_payment") {
    return cancelPrePayment({
      supabase,
      userId,
      eventId: input.event_id,
      applicationId: typedApplication.id,
      previousStatus: typedApplication.status,
    });
  }

  if (path.type === "free") {
    return cancelFreeApplication({
      supabase,
      userId,
      eventId: input.event_id,
      applicationId: typedApplication.id,
      previousStatus: typedApplication.status,
      now,
    });
  }

  return refundPaidApplication({
    supabase,
    userId,
    input,
    application: typedApplication,
    amount: path.amount,
  });
}

async function cancelPrePayment(args: {
  supabase: EFContext["supabase"];
  userId: string;
  eventId: string;
  applicationId: string;
  previousStatus: string;
}): Promise<CancelOrderServiceResult> {
  await withSpan(
    "db.delete.verification_submissions",
    "db.delete",
    () =>
      args.supabase
        .from("verification_submissions")
        .delete()
        .eq("application_id", args.applicationId)
        .eq("status", "pending"),
  );

  await withSpan(
    "db.delete.event_applications",
    "db.delete",
    () =>
      args.supabase
        .from("event_applications")
        .delete()
        .eq("id", args.applicationId),
  );

  logStatsigEvent(args.userId, "order_cancelled", undefined, {
    event_id: args.eventId,
    type: "pre_payment",
    previous_status: args.previousStatus,
  }).catch(() => {});

  return { ok: true, type: "cancelled" };
}

async function cancelFreeApplication(args: {
  supabase: EFContext["supabase"];
  userId: string;
  eventId: string;
  applicationId: string;
  previousStatus: string;
  now: Date;
}): Promise<CancelOrderServiceResult> {
  const { data: eventData, error: eventError } = await withSpan(
    "db.query.events.free_cancel",
    "db.query",
    () =>
      args.supabase
        .from("events")
        .select("start_time")
        .eq("id", args.eventId)
        .single(),
  );

  if (eventError || !eventData) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch event for free cancel",
      metadata: { detail: eventError },
    });
    return fail(500, "이벤트 정보를 가져올 수 없습니다");
  }

  const windowResult = evaluateFreeCancellationWindow(
    (eventData as { start_time: string }).start_time,
    args.now,
  );
  if (!windowResult.ok) {
    return fail(
      windowResult.status,
      windowResult.message,
      windowResult.details,
    );
  }

  const { error: updateError } = await withSpan(
    "db.update.event_applications.cancel",
    "db.update",
    () =>
      args.supabase
        .from("event_applications")
        .update({
          status: "cancelled",
          cancellation_reason: "user_requested",
          updated_at: new Date().toISOString(),
        })
        .eq("id", args.applicationId),
  );

  if (updateError) {
    log({
      function: FN,
      level: "error",
      message: "DB Update Error (free cancel)",
      metadata: { detail: updateError },
    });
  }

  logStatsigEvent(args.userId, "order_cancelled", undefined, {
    event_id: args.eventId,
    type: "free_cancelled",
    previous_status: args.previousStatus,
  }).catch(() => {});

  return { ok: true, type: "cancelled" };
}

async function refundPaidApplication(args: {
  supabase: EFContext["supabase"];
  userId: string;
  input: CancelOrderInput;
  application: CancelOrderApplicationSnapshot & {
    id: string;
    payment_id: string | null;
    paid_at: string | null;
  };
  amount: number;
}): Promise<CancelOrderServiceResult> {
  const [eventResult, policyResult] = await Promise.all([
    withSpan("db.query.events", "db.query", () =>
      args.supabase
        .from("events")
        .select("start_time")
        .eq("id", args.input.event_id)
        .single()),
    withSpan(
      "db.rpc.get_current_policy",
      "db.rpc",
      () => args.supabase.rpc("get_current_policy", { p_key: "refund" }),
    ),
  ]);

  if (eventResult.error || !eventResult.data) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch event",
      metadata: { detail: eventResult.error },
    });
    return fail(500, "Failed to verify refund eligibility");
  }

  if (policyResult.error || !policyResult.data) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch policy",
      metadata: { detail: policyResult.error },
    });
    return fail(500, "Failed to verify refund eligibility");
  }

  const policy = parseRefundPolicy(policyResult.data);
  const eligibility = verifyRefundEligibility({
    paidAt: args.application.paid_at,
    eventStartTime: (eventResult.data as { start_time: string }).start_time,
    ...policy,
  });

  if (!eligibility.eligible) {
    return {
      ok: true,
      type: "partner_refund_available",
      applicationId: args.application.id,
      reason: eligibility.reason ?? "refund_window_expired",
      deadlineHours: 72,
    };
  }

  let cancelResponse: Record<string, unknown>;
  try {
    cancelResponse = await executeRefund({
      paymentId: args.application.payment_id as string,
      reason: args.input.reason || "사용자 예매 취소",
      amount: args.amount,
      checksum: args.amount,
      fnName: FN,
    });
  } catch (error) {
    if (error instanceof RefundError) {
      return fail(error.status, error.message);
    }
    throw error;
  }

  const refundAmount = args.amount ??
    (cancelResponse.amount as number | undefined);
  const nowIso = new Date().toISOString();
  const updatePayload: Record<string, unknown> = {
    status: "cancelled",
    refund_status: "completed",
    refunded_at: nowIso,
    cancellation_reason: "user_requested",
    updated_at: nowIso,
  };
  if (refundAmount !== undefined) {
    updatePayload.refund_amount = refundAmount;
  }

  const { error: dbError } = await withSpan(
    "db.update.event_applications.refund",
    "db.update",
    () =>
      args.supabase
        .from("event_applications")
        .update(updatePayload)
        .eq("id", args.application.id),
  );

  if (dbError) {
    log({
      function: FN,
      level: "error",
      message: "DB Update Error",
      metadata: { detail: dbError },
    });
  }

  logStatsigEvent(args.userId, "order_cancelled", refundAmount, {
    event_id: args.input.event_id,
    type: "refunded",
    previous_status: args.application.status,
  }).catch(() => {});

  return { ok: true, type: "refunded", refundAmount };
}

function fail(
  status: number,
  message: string,
  details?: unknown,
): Extract<CancelOrderServiceResult, { ok: false }> {
  return { ok: false, status, message, details };
}
