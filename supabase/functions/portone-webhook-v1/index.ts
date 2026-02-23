import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";
import { initSentry, withSentry } from "../_shared/sentry_utils.ts";

const IMP_KEY = Deno.env.get("PORTONE_API_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_API_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_API_KEY, PORTONE_API_SECRET");
}

// Portone (Iamport V1) Webhook IP Whitelist
const ALLOWED_IPS = ["52.78.100.19", "52.78.48.223", "52.78.17.128", "127.0.0.1"];

initSentry();

serve(withSentry(async (req) => {
  try {
    const rawBody = await req.text();
    
    // 1. IP Validation (Primary Security Layer for V1 — V1 has no HMAC signing)
    const forwardedFor = req.headers.get("x-forwarded-for");
    const clientIp = forwardedFor ? forwardedFor.split(",")[0].trim() : "";
    
    if (clientIp && !ALLOWED_IPS.includes(clientIp)) {
      console.warn(`Blocked Webhook Request from unauthorized IP: ${clientIp}`);
      return new Response("Unauthorized IP", { status: 403 });
    }

    const body = JSON.parse(rawBody);
    const { imp_uid, merchant_uid, status } = body;
    console.log(`Webhook V1 received: ${imp_uid} (${status})`);

    if (!imp_uid || !merchant_uid) {
      return new Response("Missing parameters", { status: 400 });
    }

    // 2. Verify with Portone API (Cross-Check)
    const client = new IamportClient(IMP_KEY, IMP_SECRET);
    const payment = await client.getPayment(imp_uid);

    // 3. Consistency Check
    if (payment.merchant_uid !== merchant_uid) {
       console.error("Merchant UID mismatch:", payment.merchant_uid, merchant_uid);
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
    const updatePayload: Record<string, unknown> = {
      status: dbStatus,
      payment_id: imp_uid,
      updated_at: new Date().toISOString(),
    };
    if (payment.status === "cancelled") {
      updatePayload.refund_status = "completed";
    }
    const { error } = await supabase
      .from("event_applications")
      .update(updatePayload)
      .eq("id", merchant_uid);

    if (error) {
      console.error("DB Update Error:", error);
      return new Response("DB Error", { status: 500 });
    }

    console.log(`Updated order ${merchant_uid} to status ${dbStatus}`);

    // Send payment completion notification
    if (payment.status === "paid") {
      // Fetch user_id and event_id from the application
      const { data: application } = await supabase
        .from("event_applications")
        .select("user_id, event_id")
        .eq("id", merchant_uid)
        .single();

      if (application) {
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
    console.error("Webhook Error:", errorMessage);
    return new Response(errorMessage, { status: 500 });
  }
}));
