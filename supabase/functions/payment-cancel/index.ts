import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withSentry } from "../_shared/sentry_utils.ts";

initSentry();

Deno.serve(withSentry(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  try {
    // 1. Parse Request
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }
    const { payment_id, reason, amount, checksum } = reqBody as {
      payment_id?: string;
      reason?: string;
      amount?: number;
      checksum?: number;
    };

    if (!payment_id) {
      return errorResponse("Missing payment_id", 400);
    }

    // 1.5 Init Supabase (reused throughout)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1.5a Fetch application for eligibility check
    const { data: application, error: appError } = await supabase
      .from("event_applications")
      .select("paid_at, event_id, refund_status")
      .eq("payment_id", payment_id)
      .single();

    if (appError || !application) {
      return errorResponse("Application not found", 404);
    }

    // 1.5b Prevent double refund
    if (application.refund_status !== "none") {
      return errorResponse("already_refunded", 400, {
        reason: "Refund already processed",
      });
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
      console.error("Failed to fetch event:", eventResult.error);
      return errorResponse("Failed to verify refund eligibility", 500);
    }

    if (policyResult.error || !policyResult.data) {
      console.error("Failed to fetch policy:", policyResult.error);
      return errorResponse("Failed to verify refund eligibility", 500);
    }

    {
      const policy = policyResult.data as Record<string, number>;
      const gracePeriodHours = policy.grace_period_hours ?? 2;
      const cutoffDays = policy.cutoff_days ?? 7;
      const now = new Date();
      const paidAt = application.paid_at ? new Date(application.paid_at) : null;
      const eventStart = new Date(eventResult.data.start_time);

      const withinGracePeriod =
        paidAt !== null &&
        now.getTime() - paidAt.getTime() <=
          gracePeriodHours * 60 * 60 * 1000;
      const withinCutoff =
        eventStart.getTime() - now.getTime() >=
          cutoffDays * 24 * 60 * 60 * 1000;

      if (!withinGracePeriod && !withinCutoff) {
        return errorResponse("refund_not_eligible", 400, {
          reason: "Refund window has expired",
        });
      }
    }

    // 2. Init IamportClient
    const impKey = Deno.env.get("PORTONE_API_KEY");
    const impSecret = Deno.env.get("PORTONE_API_SECRET");

    if (!impKey || !impSecret) {
      console.error("Missing Portone credentials");
      return errorResponse("Server configuration error", 500);
    }

    // 3. Cancel Payment via IamportClient
    const client = new IamportClient(impKey, impSecret);
    let cancelResponse: Record<string, unknown>;
    try {
      cancelResponse = await client.cancelPayment(
        payment_id,
        reason || "심사 반려로 인한 자동 환불",
        amount,
        checksum,
      );
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error("Failed to cancel payment:", message);
      if (message.startsWith("Failed to get token") || message.startsWith("Iamport Error")) {
        return errorResponse("Payment provider error", 502);
      }
      return errorResponse(message, 400);
    }

    // 4. Update DB: refund_status + refund_amount
    const refundAmount = amount ?? (cancelResponse.amount as number | undefined);
    const updatePayload: Record<string, unknown> = {
      refund_status: "completed",
      updated_at: new Date().toISOString(),
    };
    if (refundAmount !== undefined) {
      updatePayload.refund_amount = refundAmount;
    }
    const { error: dbError } = await supabase
      .from("event_applications")
      .update(updatePayload)
      .eq("payment_id", payment_id);

    if (dbError) {
      console.error("DB Update Error:", dbError);
      // Non-fatal: payment was cancelled, just log the DB error
    }

    // 5. Success
    return successResponse({ success: true, data: cancelResponse });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in payment-cancel:", message);
    return errorResponse(message, 500);
  }
}));
