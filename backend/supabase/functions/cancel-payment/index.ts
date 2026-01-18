import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const PORTONE_API_URL = "https://api.iamport.kr";

serve(async (req) => {
  try {
    // 1. Parse Request
    const { payment_id, reason } = await req.json();

    if (!payment_id) {
      return new Response(JSON.stringify({ error: "Missing payment_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Get Portone Access Token
    const impKey = Deno.env.get("PORTONE_API_KEY");
    const impSecret = Deno.env.get("PORTONE_API_SECRET");

    if (!impKey || !impSecret) {
      console.error("Missing Portone credentials");
      return new Response(JSON.stringify({ error: "Server configuration error" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const tokenRes = await fetch(`${PORTONE_API_URL}/users/getToken`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ imp_key: impKey, imp_secret: impSecret }),
    });

    const tokenData = await tokenRes.json();
    if (tokenData.code !== 0) {
      console.error("Failed to get Portone token:", tokenData.message);
      return new Response(JSON.stringify({ error: "Payment provider error" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }

    const accessToken = tokenData.response.access_token;

    // 3. Cancel Payment
    const cancelRes = await fetch(`${PORTONE_API_URL}/payments/cancel`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": accessToken,
      },
      body: JSON.stringify({
        imp_uid: payment_id,
        reason: reason || "심사 반려로 인한 자동 환불",
      }),
    });

    const cancelData = await cancelRes.json();

    if (cancelData.code !== 0) {
      console.error("Failed to cancel payment:", cancelData.message);
      return new Response(JSON.stringify({ error: cancelData.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Success
    return new Response(JSON.stringify({ success: true, data: cancelData.response }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (e) {
    console.error("Error in cancel-payment:", e);
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
