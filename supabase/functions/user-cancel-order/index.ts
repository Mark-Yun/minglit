import { createClient } from "@supabase/supabase-js";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";
import { verifyRefundEligibility, executeRefund, RefundError } from "../_shared/refund_utils.ts";

const FN = "user-cancel-order";

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    // 1. Parse Request
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { event_id, reason } = reqBody as {
      event_id?: string;
      reason?: string;
    };

    if (!event_id) {
      return errorResponse("Missing required field: event_id", 400);
    }

    // 2. Init Supabase (service role for cross-table operations)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // 3. Fetch application by (event_id, user_id)
    const { data: application, error: appError } = await withSpan(
      "db.query.event_applications", "db.query",
      () => supabase
        .from("event_applications")
        .select("id, status, payment_id, payment_amount, paid_at, refund_status, event_id, user_id")
        .eq("event_id", event_id)
        .eq("user_id", userId)
        .single(),
    );

    if (appError || !application) {
      return errorResponse("해당 이벤트에 신청 내역이 없습니다", 404);
    }

    // 4. Status validation
    const { status } = application;
    if (status === "cancelled" || status === "rejected") {
      return errorResponse("이미 취소/거절된 신청입니다", 400);
    }

    // 5. Branch: pre-payment vs post-payment
    const isPaid = status === "paid" || status === "pending_review" || status === "approved";
    const isPrePayment = status === "pending" || status === "payment_failed";

    if (isPrePayment) {
      // Pre-payment cancellation: delete verification_submissions + delete application
      await withSpan(
        "db.delete.verification_submissions", "db.delete",
        () => supabase
          .from("verification_submissions")
          .delete()
          .eq("application_id", application.id)
          .eq("status", "pending"),
      );

      await withSpan(
        "db.delete.event_applications", "db.delete",
        () => supabase
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

      // Free event (payment_amount = 0 or null): just update status
      if (!paymentAmount || paymentAmount === 0) {
        const { error: updateError } = await withSpan(
          "db.update.event_applications.cancel", "db.update",
          () => supabase
            .from("event_applications")
            .update({
              status: "cancelled",
              updated_at: new Date().toISOString(),
            })
            .eq("id", application.id),
        );

        if (updateError) {
          log({ function: FN, level: "error", message: "DB Update Error (free cancel)", metadata: { detail: updateError } });
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
            .single(),
        ),
        withSpan("db.rpc.get_current_policy", "db.rpc", () =>
          supabase.rpc("get_current_policy", { p_key: "refund" }),
        ),
      ]);

      if (eventResult.error || !eventResult.data) {
        log({ function: FN, level: "error", message: "Failed to fetch event", metadata: { detail: eventResult.error } });
        return errorResponse("Failed to verify refund eligibility", 500);
      }

      if (policyResult.error || !policyResult.data) {
        log({ function: FN, level: "error", message: "Failed to fetch policy", metadata: { detail: policyResult.error } });
        return errorResponse("Failed to verify refund eligibility", 500);
      }

      const policy = policyResult.data as Record<string, number>;
      const gracePeriodHours = policy.grace_period_hours ?? 2;
      const cutoffDays = policy.cutoff_days ?? 7;

      const eligibility = verifyRefundEligibility({
        paidAt: application.paid_at as string | null,
        eventStartTime: eventResult.data.start_time,
        gracePeriodHours,
        cutoffDays,
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

      // Update DB: refund_status + refund_amount
      const refundAmount = paymentAmount ?? (cancelResponse.amount as number | undefined);
      const updatePayload: Record<string, unknown> = {
        refund_status: "completed",
        updated_at: new Date().toISOString(),
      };
      if (refundAmount !== undefined) {
        updatePayload.refund_amount = refundAmount;
      }

      const { error: dbError } = await withSpan(
        "db.update.event_applications.refund", "db.update",
        () => supabase
          .from("event_applications")
          .update(updatePayload)
          .eq("id", application.id),
      );

      if (dbError) {
        log({ function: FN, level: "error", message: "DB Update Error", metadata: { detail: dbError } });
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
    log({ function: FN, level: "error", message: `Unhandled status: ${status}`, metadata: { application_id: application.id } });
    return errorResponse("지원하지 않는 신청 상태입니다", 400);

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: `Error in user-cancel-order: ${message}` });
    return errorResponse(message, 500);
  }
}));
