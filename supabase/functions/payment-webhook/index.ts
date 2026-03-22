// TODO: verify_jwt=false 설정 후, 포트원 서버 호출자 검증 강화 필요
// 현재: IP whitelist만 사용 (ALLOWED_IPS)
// 추가 필요: 포트원 V1 webhook signature 검증 또는 HMAC 검증
// 참고: V1은 HMAC 미지원이므로 IP whitelist가 1차 보안. 추가 보안 레이어 검토 필요.
import { createClient } from "@supabase/supabase-js";
import { IamportClient } from "../_shared/iamport_client.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "payment-webhook";

const IMP_KEY = Deno.env.get("PORTONE_API_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_API_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_API_KEY, PORTONE_API_SECRET");
}

// Portone (Iamport V1) Webhook IP Whitelist
const ALLOWED_IPS = ["52.78.100.19", "52.78.48.223", "52.78.17.128", "127.0.0.1"];

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  try {
    const rawBody = await req.text();

    // 1. IP Validation (Primary Security Layer for V1 — V1 has no HMAC signing)
    const forwardedFor = req.headers.get("x-forwarded-for");
    const clientIp = forwardedFor ? forwardedFor.split(",")[0].trim() : "";

    if (!clientIp || !ALLOWED_IPS.includes(clientIp)) {
      log({ function: FN, level: "warn", message: `Blocked Webhook Request from unauthorized IP: ${clientIp || "(empty)"}` });
      return new Response("Unauthorized IP", { status: 403 });
    }

    let body: Record<string, unknown>;
    try {
      body = JSON.parse(rawBody);
    } catch {
      log({ function: FN, level: "warn", message: "Malformed JSON body received" });
      return new Response("Bad Request", { status: 400 });
    }
    const { imp_uid, merchant_uid, status } = body as { imp_uid?: string; merchant_uid?: string; status?: string };
    log({ function: FN, level: "info", message: `Webhook V1 received: ${imp_uid} (${status})` });

    if (!imp_uid || !merchant_uid) {
      return new Response("Missing parameters", { status: 400 });
    }

    // 2. Verify with Portone API (Cross-Check)
    const client = new IamportClient(IMP_KEY, IMP_SECRET);
    const payment = await client.getPayment(imp_uid);

    // 3. Consistency Check
    if (payment.merchant_uid !== merchant_uid) {
      log({ function: FN, level: "error", message: "Merchant UID mismatch", metadata: { received: merchant_uid, actual: payment.merchant_uid } });
      return new Response("Merchant UID mismatch", { status: 400 });
    }

    // 4. Update DB (idempotent)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    let dbStatus = "pending";
    // Map Iamport status to Minglit status
    switch (payment.status) {
      case "paid":
        dbStatus = "approved"; // 결제 완료 -> 승인 (티켓 발권 트리거)
        break;
      case "cancelled":
        dbStatus = "cancelled"; // 결제 취소 -> 취소
        break;
      case "failed":
        dbStatus = "payment_failed"; // 결제 실패
        break;
      case "ready":
        dbStatus = "payment_pending"; // 가상계좌 발급 등
        break;
      default:
        dbStatus = `unknown_${payment.status}`;
    }

     // Update event_applications table
     // Fix #133: paid_at 없을 때 now로 폴백하면 재시도마다 paid_at이 밀려 멱등성 깨짐 — 실제 결제 시각이 있을 때만 업데이트
     const paidAtIso = payment.paid_at && payment.paid_at > 0
       ? new Date(payment.paid_at * 1000).toISOString()
       : null;

     const updatePayload: Record<string, unknown> = {
       status: dbStatus,
       payment_id: imp_uid,
       updated_at: new Date().toISOString(),
       ...(payment.status === "paid" && paidAtIso ? { paid_at: paidAtIso } : {}),
     };
     if (payment.status === "cancelled") {
       updatePayload.refund_status = "completed";
     }
    const { error } = await supabase
      .from("event_applications")
      .update(updatePayload)
      .eq("id", merchant_uid);

    if (error) {
      log({ function: FN, level: "error", message: "DB Update Error", metadata: { detail: error } });
      return new Response("DB Error", { status: 500 });
    }

    log({ function: FN, level: "info", message: `Updated order ${merchant_uid} to status ${dbStatus}` });

    if (payment.status === "failed") {
      logStatsigEvent(merchant_uid, 'payment_failed', undefined, { reason: 'payment_failed', imp_uid, merchant_uid }).catch(() => {});
    }

    // Send payment completion notification
    if (payment.status === "paid") {
      // Fetch user_id and event_id from the application
      const { data: application } = await supabase
        .from("event_applications")
        .select("user_id, event_id")
        .eq("id", merchant_uid)
        .single();

      if (application) {
        logStatsigEvent(application.user_id, 'payment_completed', payment.amount, { imp_uid, merchant_uid }).catch(() => {});
        // TODO: Migrate to produce_event() pattern via q_global_events
        // Currently sends directly to q_notifications, bypassing 2-tier architecture
        // See: docs/architecture/global-event-pipeline.md
        await supabase.rpc("pgmq_send", {
          queue_name: "q_notifications",
          message: {
            id: crypto.randomUUID(),
            type: "payment_complete",
            user_id: application.user_id,
            title: "[결제 완료]",
            body: "결제가 완료되었습니다.",
            category: "service",
            data: {
              event_id: application.event_id,
              deep_link: `/events/${application.event_id}`,
            },
            meta: { occurred_at: new Date().toISOString() },
          },
        });
      }
    }
    return new Response("OK", { status: 200 });

  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: `Webhook Error: ${errorMessage}` });
    return new Response(errorMessage, { status: 500 });
  }
}));
