// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "../_shared/supabase_client.ts";
import { nowISO } from "../_shared/temporal_utils.ts";
import { IamportClient } from "../_shared/iamport_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";

const FN = "payment-verify";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const IMP_KEY = Deno.env.get("PORTONE_API_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_API_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_API_KEY, PORTONE_API_SECRET");
}

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
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
    const supabase = createServiceClient();

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
      await client.cancelPayment(imp_uid, "결제 금액 위변조로 자동 취소").catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : String(e);
        log({ function: FN, level: "error", message: "Cancel on mismatch failed", metadata: { detail: msg } });
      });
      logStatsigEvent(auth, 'payment_failed', undefined, { reason: 'amount_mismatch', imp_uid }).catch(() => {});
      return errorResponse("Amount mismatch", 400, {
        expected: order.payment_amount,
        actual: payment.amount,
      });
    }

    // Fix #133: paid_at 없을 때 now 폴백하면 재시도마다 값이 밀려 멱등성 깨짐 — payment-webhook과 동일하게 null 처리
    const paidAtIso = payment.paid_at && payment.paid_at > 0
      ? Temporal.Instant.fromEpochMilliseconds(payment.paid_at * 1000).toString()
      : null;

    const { error: updateError } = await withSpan(
      'db.update.event_applications',
      'db.update',
      async () => supabase
        .from("event_applications")
        .update({
          status: "approved",
          payment_id: imp_uid,
          ...(paidAtIso ? { paid_at: paidAtIso } : {}),
          updated_at: nowISO(),
        })
        .eq("id", merchant_uid)
    );

    if (updateError) {
      log({ function: FN, level: "error", message: "DB Update Error", metadata: { detail: updateError } });
      logStatsigEvent(auth, 'payment_failed', undefined, { reason: 'db_update_error', imp_uid }).catch(() => {});
      return errorResponse("Failed to update order status", 500);
    }

    logStatsigEvent(auth, 'payment_completed', payment.amount, { imp_uid, merchant_uid }).catch(() => {});
    return successResponse({ success: true, imp_uid });


  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({ function: FN, level: "error", message: "Error in payment-verify", metadata: { detail: message } });
    return errorResponse(message, 500);
  }
}));
