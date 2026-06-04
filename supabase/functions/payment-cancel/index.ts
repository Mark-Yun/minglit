// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
// Fix #2185 (Batch 7): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { nowISO } from "../_shared/temporal_utils.ts";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
// Fix #299: 환불 로직을 shared 모듈로 추출 — user-cancel-order와 공유
import { executeRefund, RefundError } from "../_shared/refund_utils.ts";
import {
  parseRefundPolicy,
  verifyRefundEligibility,
} from "../_shared/domains/payment/refund_policy.ts";

const FN = "payment-cancel";

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  const { supabase } = ctx;
  if (ctx.auth.type !== "user" && ctx.auth.type !== "system") {
    return errorResponse("Unexpected auth type", 500);
  }

  try {
    // 1. Parse Request
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;
    const { payment_id, reason, amount, checksum } = body as {
      payment_id?: string;
      reason?: string;
      amount?: number;
      checksum?: number;
    };

    if (!payment_id) {
      return errorResponse("Missing payment_id", 400);
    }

    // 1.5a Fetch application for eligibility check
    const { data: application, error: appError } = await supabase
      .from("event_applications")
      .select("paid_at, event_id, refund_status, user_id, status")
      .eq("payment_id", payment_id)
      .single();

    if (appError || !application) {
      return errorResponse("Application not found", 404);
    }

    if (ctx.auth.type === "user") {
      // Fix #133: 호출자가 신청자 본인인지 검증 — service role은 RLS를 우회하므로 명시적 확인 필요
      if (application.user_id !== ctx.auth.userId) {
        return errorResponse("Forbidden", 403);
      }

      // 1.5b Prevent double refund for direct user calls.
      if (application.refund_status !== "none") {
        return errorResponse("already_refunded", 400, {
          reason: "Refund already processed",
        });
      }
    } else {
      // DB-trigger automatic refunds are system-only and only valid after partner rejection.
      // The trigger sets refund_status=requested before the async pg_net call lands.
      if (application.status !== "rejected") {
        return errorResponse(
          "system_refund_requires_rejected_application",
          403,
        );
      }
      if (
        application.refund_status !== "none" &&
        application.refund_status !== "requested"
      ) {
        return errorResponse("already_refunded", 400, {
          reason: "Refund already processed",
        });
      }
    }

    // 1.5c Verify refund eligibility against policy
    const [eventResult, policyResult] = await Promise.all([
      supabase
        .from("events")
        .select("start_time")
        .eq("id", application.event_id)
        .single(),
      supabase.rpc("get_current_policy", { p_key: "refund" }),
    ]);

    // Fix #133: 이벤트/정책 조회 실패 시 적격성 검사를 건너뛰지 않고 명시적으로 에러 반환
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

    // Fix #299: 환불 적격성 검증을 shared 모듈로 위임
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

    // Fix #299: PortOne 환불 실행을 shared 모듈로 위임
    let cancelResponse: Record<string, unknown>;
    try {
      cancelResponse = await executeRefund({
        paymentId: payment_id,
        reason: reason || "심사 반려로 인한 자동 환불",
        amount,
        checksum,
        fnName: FN,
      });
    } catch (e) {
      if (e instanceof RefundError) {
        return errorResponse(e.message, e.status);
      }
      throw e;
    }

    // 4. Update DB: refund_status + refund_amount + refunded_at
    const refundAmount = amount ??
      (cancelResponse.amount as number | undefined);
    const refundedAt = nowISO();
    const updatePayload: Record<string, unknown> = {
      refund_status: "completed",
      // Fix #2099: 환불 처리 시점 기록
      refunded_at: refundedAt,
      updated_at: refundedAt,
    };
    if (refundAmount !== undefined) {
      updatePayload.refund_amount = refundAmount;
    }
    const { error: dbError } = await supabase
      .from("event_applications")
      .update(updatePayload)
      .eq("payment_id", payment_id);

    if (dbError) {
      log({
        function: FN,
        level: "error",
        message: "DB Update Error",
        metadata: { detail: dbError },
      });
      // Non-fatal: payment was cancelled, just log the DB error
    }

    // 5. Success
    return successResponse({ success: true, data: cancelResponse });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: `Error in payment-cancel: ${message}`,
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
