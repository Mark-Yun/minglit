import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";

const PORTONE_API_URL = "https://api.iamport.kr";

serve(async (req) => {
  try {
    // 1. Parse Request
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }
    const { payment_id, reason } = reqBody as { payment_id?: string; reason?: string };

    if (!payment_id) {
      return errorResponse("Missing payment_id", 400);
    }

    // 2. Get Portone Access Token
    const impKey = Deno.env.get("PORTONE_API_KEY");
    const impSecret = Deno.env.get("PORTONE_API_SECRET");

    if (!impKey || !impSecret) {
      console.error("Missing Portone credentials");
      return errorResponse("Server configuration error", 500);
    }

    const tokenRes = await fetch(`${PORTONE_API_URL}/users/getToken`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ imp_key: impKey, imp_secret: impSecret }),
    });

    const tokenData = await tokenRes.json();
    if (tokenData.code !== 0) {
      console.error("Failed to get Portone token:", tokenData.message);
      return errorResponse("Payment provider error", 502);
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
      return errorResponse(cancelData.message, 400);
    }

    // 4. Success
    return successResponse({ success: true, data: cancelData.response });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in cancel-payment:", message);
    return errorResponse(message, 500);
  }
});
