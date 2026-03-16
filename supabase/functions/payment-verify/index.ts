import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withSentry, withSpan } from "../_shared/sentry_utils.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const IMP_KEY = Deno.env.get("PORTONE_API_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_API_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_API_KEY, PORTONE_API_SECRET");
}

initSentry();
initStatsig();

Deno.serve(withSentry(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  try {
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }
    const { imp_uid, merchant_uid } = reqBody as { imp_uid?: string; merchant_uid?: string };

    if (!imp_uid || !merchant_uid) {
      return errorResponse("Missing required parameters", 400);
    }

    // 0. Supabase Client 초기화
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 1. DB에서 주문 정보 조회 (금액 확인)
    const { data: order, error: orderError } = await withSpan(
      'db.query.event_applications',
      'db.query',
      async () => supabase
        .from("event_applications")
        .select("payment_amount, status")
        .eq("id", merchant_uid)
        .single()
    );

    if (orderError || !order) {
      return errorResponse("Order not found", 404);
    }

    // 이미 처리된 주문인지 확인
    if (order.status === 'approved' || order.status === 'paid') {
      return successResponse({ success: true, message: "Already processed" });
    }

    // 2. Iamport V1 API 조회
    const client = new IamportClient(IMP_KEY, IMP_SECRET);
    const payment = await client.getPayment(imp_uid);

    // 3. 결제 상태 및 금액 검증
    if (payment.status !== "paid") {
      logStatsigEvent(auth, 'payment_failed', undefined, { reason: 'payment_not_completed', imp_uid }).catch(() => {});
      return errorResponse("Payment not completed", 400, { status: payment.status });
    }

    if (payment.amount !== order.payment_amount) {
      client.cancelPayment(imp_uid, "결제 금액 위변조로 자동 취소").catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : String(e);
        console.error("Cancel on mismatch failed:", msg);
      });
      logStatsigEvent(auth, 'payment_failed', undefined, { reason: 'amount_mismatch', imp_uid }).catch(() => {});
      return errorResponse("Amount mismatch", 400, {
        expected: order.payment_amount,
        actual: payment.amount,
      });
    }

    const paidAtIso = payment.paid_at && payment.paid_at > 0
      ? new Date(payment.paid_at * 1000).toISOString()
      : new Date().toISOString();

    const { error: updateError } = await withSpan(
      'db.update.event_applications',
      'db.update',
      async () => supabase
        .from("event_applications")
        .update({
          status: "approved",
          payment_id: imp_uid,
          paid_at: paidAtIso,
          updated_at: new Date().toISOString(),
        })
        .eq("id", merchant_uid)
    );

    if (updateError) {
      console.error("DB Update Error:", updateError);
      logStatsigEvent(auth, 'payment_failed', undefined, { reason: 'db_update_error', imp_uid }).catch(() => {});
      return errorResponse("Failed to update order status", 500);
    }

    logStatsigEvent(auth, 'payment_completed', payment.amount, { imp_uid, merchant_uid }).catch(() => {});
    return successResponse({ success: true, imp_uid });


  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("Error in payment-verify:", message);
    return errorResponse(message, 500);
  }
}));
