// Fix #1892: 호출자 검증 강화 (H1 — 127.0.0.1 prod 제거, H2 — XFF 파싱 개선)
// V1은 HMAC 미지원이므로 IP whitelist + Portone cross-check가 방어선. V2 마이그레이션 시 HMAC 추가 가능.
// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "../_shared/supabase_client.ts";
import { IamportClient } from "../_shared/iamport_client.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";
import { nowISO } from "../_shared/temporal_utils.ts";

const FN = "payment-webhook";

const IMP_KEY = Deno.env.get("PORTONE_API_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_API_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_API_KEY, PORTONE_API_SECRET");
}

// Portone (Iamport V1) Webhook IP Whitelist
// Fix #1892 H1: 127.0.0.1은 dev 환경에서만 허용 — production에서 localhost를 허용하면
// X-Forwarded-For 스푸핑으로 IP 게이트가 무력화될 수 있음
const _IS_DEV_ENV = Deno.env.get("ENVIRONMENT") === "dev";
const ALLOWED_IPS = _IS_DEV_ENV
  ? ["52.78.100.19", "52.78.48.223", "52.78.17.128", "127.0.0.1"]
  : ["52.78.100.19", "52.78.48.223", "52.78.17.128"];

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  try {
    const rawBody = await req.text();

    // 1. IP Validation (Primary Security Layer for V1 — V1 has no HMAC signing)
    // Fix #1892 H2: 우선순위 — edge/CDN이 주입하는 헤더를 신뢰, 클라이언트가 조작 가능한 leftmost XFF 금지.
    //   1) x-real-ip: Supabase Edge/CDN이 실제 연결 IP로 설정
    //   2) cf-connecting-ip: Cloudflare가 설정하는 클라이언트 IP (Supabase가 CF 인프라 사용 시)
    //   3) XFF rightmost fallback: CDN이 XFF에 연결 IP를 append하는 구조에서의 안전한 fallback.
    //      leftmost는 클라이언트가 임의 조작 가능하므로 사용하지 않음.
    const clientIp =
      req.headers.get("x-real-ip")?.trim() ||
      req.headers.get("cf-connecting-ip")?.trim() ||
      req.headers.get("x-forwarded-for")?.split(",").map((s) => s.trim()).filter(Boolean).pop() ||
      "";

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

    // Fix #1949: Idempotency check — reject replayed webhooks before hitting PortOne API.
    // SELECT-first is intentional: INSERT-first would consume the key on transient failures,
    // blocking PortOne retries. We insert only after a successful DB update below.
    const supabase = createServiceClient();
    const { data: existingLog } = await supabase
      .from("webhook_imp_uid_log")
      .select("imp_uid")
      .eq("imp_uid", imp_uid)
      .maybeSingle();
    if (existingLog) {
      log({ function: FN, level: "info", message: `Duplicate webhook rejected (already processed): ${imp_uid}` });
      return new Response("OK", { status: 200 });
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
       ? Temporal.Instant.fromEpochMilliseconds(payment.paid_at * 1000).toString()
       : null;

     const updatePayload: Record<string, unknown> = {
       status: dbStatus,
       payment_id: imp_uid,
       updated_at: nowISO(),
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

    // Fix #1949: Record successful processing so retries/replays are blocked above.
    await supabase
      .from("webhook_imp_uid_log")
      .insert({ imp_uid, merchant_uid });

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
        // Fix #2026: direct q_notifications push — tracked for migration to produce_event() pattern
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
            meta: { occurred_at: nowISO() },
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
