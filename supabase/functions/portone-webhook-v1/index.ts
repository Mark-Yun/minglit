import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { IamportClient } from "../_shared/iamport_client.ts";

const IMP_KEY = Deno.env.get("PORTONE_IMP_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_IMP_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error("Missing required environment variables: PORTONE_IMP_KEY, PORTONE_IMP_SECRET");
}

// Portone (Iamport V1) Webhook IP Whitelist
const ALLOWED_IPS = ["52.78.100.19", "52.78.48.223", "52.78.17.128", "127.0.0.1"];

serve(async (req) => {
  try {
    // 1. IP Validation
    // SECURITY: x-forwarded-for can be spoofed unless set by a trusted proxy.
    // TODO: Verify a PortOne webhook signature (HMAC header) when available and
    // prefer trusted proxy/edge-provided client IP over raw headers.
    const forwardedFor = req.headers.get("x-forwarded-for");
    const clientIp = forwardedFor ? forwardedFor.split(",")[0].trim() : "";
    
    // In local development, clientIp might be null or loopback.
    // For production, ensure this check is enabled.
    if (clientIp && !ALLOWED_IPS.includes(clientIp)) {
      console.warn(`Blocked Webhook Request from unauthorized IP: ${clientIp}`);
      return new Response("Unauthorized IP", { status: 403 });
    }

    const body = await req.json();
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

    // 4. Update DB
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
    // Note: This update should be idempotent.
    const { error } = await supabase
      .from("event_applications")
      .update({
        status: dbStatus,
        payment_id: imp_uid,
        updated_at: new Date().toISOString(),
        // payment_data: payment, // Optional: Save full payment data if column exists
      })
      .eq("id", merchant_uid);

    if (error) {
      console.error("DB Update Error:", error);
      return new Response("DB Error", { status: 500 });
    }

    console.log(`Updated order ${merchant_uid} to status ${dbStatus}`);
    return new Response("OK", { status: 200 });

  } catch (e) {
    const errorMessage = e instanceof Error ? e.message : String(e);
    console.error("Webhook Error:", errorMessage);
    return new Response(errorMessage, { status: 500 });
  }
});
