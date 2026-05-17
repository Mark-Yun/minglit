// Fix #2185 (Batch 5): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";
import { executeRefund, RefundError } from "../_shared/refund_utils.ts";
import {
  classifyApplicationStatus,
  isEventStarted,
  isFreeApplication,
} from "../_shared/domains/payment/application_status.ts";
import {
  parseRefundPolicy,
  verifyRefundEligibility,
} from "../_shared/domains/payment/refund_policy.ts";

const FN = "user-cancel-order";

initStatsig();

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (ctx.auth.type !== "user") return errorResponse("Unexpected auth type", 500);
  const userId = ctx.auth.userId;
  const { supabase } = ctx;

  try {
    // 1. Parse Request
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const { event_id, reason } = body as {
      event_id?: string;
      reason?: string;
    };

    if (!event_id) {
      return errorResponse("Missing required field: event_id", 400);
    }

    // 2. Fetch application by (event_id, user_id)
    const { data: application, error: appError } = await withSpan(
      "db.query.event_applications",
      "db.query",
      () =>
        supabase
          .from("event_applications")
          .select(
            "id, status, payment_id, payment_amount, paid_at, refund_status, event_id, user_id",
          )
          .eq("event_id", event_id)
          .eq("user_id", userId)
          .single(),
    );

    if (appError || !application) {
      return errorResponse("해당 이벤트에 신청 내역이 없습니다", 404);
    }

    // 3. Status validation + classify
    const { status } = application;
    const { isPaid, isPrePayment, isFinal } = classifyApplicationStatus(status);
    if (isFinal) {
      return errorResponse("이미 취소/거절된 신청입니다", 400);
    }

    if (isPrePayment) {
      // Pre-payment cancellation: delete verification_submissions + delete application
      await withSpan(
        "db.delete.verification_submissions",
        "db.delete",
        () =>
          supabase
            .from("verification_submissions")
            .delete()
            .eq("application_id", application.id)
            .eq("status", "pending"),
      );

      await withSpan(
        "db.delete.event_applications",
        "db.delete",
        () =>
          supabase
            .from("event_applications")
            .delete()
            .eq("id", application.id),
      );

      logStatsigEvent(userId, "order_cancelled", undefined, {
        event_id,
        type: "pre_payment",
        previous_status: status,
      }).catch(() => {});

      return successResponse({ success: true, type: "cancelled" });
    }

    if (isPaid) {
      const paymentAmount = application.payment_amount as number | null;

      // Fix #1652: payment_amount=null means damaged data — reject, do not treat as free.
      if (paymentAmount === null) {
        log({
          function: FN,
          level: "error",
          message: "Damaged data: payment_amount=null on paid application",
          metadata: { application_id: application.id },
        });
        return errorResponse("결제 정보가 손상된 신청입니다", 400);
      }

      // Free event (payment_amount === 0): verify event hasn't started, then cancel.
      if (isFreeApplication(paymentAmount)) {
        const { data: eventData, error: eventError } = await withSpan(
          "db.query.events.free_cancel",
          "db.query",
          () =>
            supabase
              .from("events")
              .select("start_time")
              .eq("id", event_id)
              .single(),
        );

        if (eventError || !eventData) {
          log({
            function: FN,
            level: "error",
            message: "Failed to fetch event for free cancel",
            metadata: { detail: eventError },
          });
          return errorResponse("이벤트 정보를 가져올 수 없습니다", 500);
        }

        if (isEventStarted(eventData.start_time)) {
          return errorResponse("refund_not_eligible", 400, {
            reason: "event_already_started",
          });
        }

        const { error: updateError } = await withSpan(
          "db.update.event_applications.cancel",
          "db.update",
          () =>
            supabase
              .from("event_applications")
              .update({
                status: "cancelled",
                // Fix #2099: 취소 사유 기록 — system vs user 구분
                cancellation_reason: "user_requested",
                updated_at: new Date().toISOString(),
              })
              .eq("id", application.id),
        );

        if (updateError) {
          log({
            function: FN,
            level: "error",
            message: "DB Update Error (free cancel)",
            metadata: { detail: updateError },
          });
        }

        logStatsigEvent(userId, "order_cancelled", undefined, {
          event_id,
          type: "free_cancelled",
          previous_status: status,
        }).catch(() => {});

        return successResponse({ success: true, type: "cancelled" });
      }

      // Paid event: check refund eligibility
      if (application.refund_status !== "none") {
        return errorResponse("already_refunded", 400, {
          reason: "Refund already processed",
        });
      }

      // Fetch event + refund policy
      const [eventResult, policyResult] = await Promise.all([
        withSpan("db.query.events", "db.query", () =>
          supabase
            .from("events")
            .select("start_time")
            .eq("id", event_id)
            .single()),
        withSpan(
          "db.rpc.get_current_policy",
          "db.rpc",
          () => supabase.rpc("get_current_policy", { p_key: "refund" }),
        ),
      ]);

      if (eventResult.error || !eventResult.data) {
        log({
          function: FN,
          level: "error",
          message: "Failed to fetch event",
          metadata: { detail: eventResult.error },
        });
        return errorResponse("Failed to verify refund eligibility", 500);
      }

      if (policyResult.error || !policyResult.data) {
        log({
          function: FN,
          level: "error",
          message: "Failed to fetch policy",
          metadata: { detail: policyResult.error },
        });
        return errorResponse("Failed to verify refund eligibility", 500);
      }

      const policy = parseRefundPolicy(policyResult.data);
      const eligibility = verifyRefundEligibility({
        paidAt: application.paid_at as string | null,
        eventStartTime: eventResult.data.start_time,
        ...policy,
      });

      if (!eligibility.eligible) {
        return errorResponse("refund_not_eligible", 400, {
          reason: eligibility.reason,
        });
      }

      // Execute refund via PortOne
      let cancelResponse: Record<string, unknown>;
      try {
        cancelResponse = await executeRefund({
          paymentId: application.payment_id as string,
          reason: reason || "사용자 예매 취소",
          amount: paymentAmount,
          checksum: paymentAmount,
          fnName: FN,
        });
      } catch (e) {
        if (e instanceof RefundError) {
          return errorResponse(e.message, e.status);
        }
        throw e;
      }

      // Update DB: status=cancelled + refund_status + refund_amount
      // Fix #1515: Set status='cancelled' so on_application_cancel trigger removes event_participants
      const refundAmount = paymentAmount ??
        (cancelResponse.amount as number | undefined);
      const nowISO = new Date().toISOString();
      const updatePayload: Record<string, unknown> = {
        status: "cancelled",
        refund_status: "completed",
        // Fix #2099: 환불 처리 시점 + 취소 사유 기록
        refunded_at: nowISO,
        cancellation_reason: "user_requested",
        updated_at: nowISO,
      };
      if (refundAmount !== undefined) {
        updatePayload.refund_amount = refundAmount;
      }

      const { error: dbError } = await withSpan(
        "db.update.event_applications.refund",
        "db.update",
        () =>
          supabase
            .from("event_applications")
            .update(updatePayload)
            .eq("id", application.id),
      );

      if (dbError) {
        log({
          function: FN,
          level: "error",
          message: "DB Update Error",
          metadata: { detail: dbError },
        });
        // Non-fatal: payment was already refunded
      }

      logStatsigEvent(userId, "order_cancelled", refundAmount, {
        event_id,
        type: "refunded",
        previous_status: status,
      }).catch(() => {});

      return successResponse({
        success: true,
        type: "refunded",
        data: { refund_amount: refundAmount },
      });
    }

    // Unhandled status
    log({
      function: FN,
      level: "error",
      message: `Unhandled status: ${status}`,
      metadata: { application_id: application.id },
    });
    return errorResponse("지원하지 않는 신청 상태입니다", 400);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: `Error in user-cancel-order: ${message}`,
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
