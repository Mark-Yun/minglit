import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { IamportClient } from "../_shared/iamport_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { initSentry, withSentry } from "../_shared/sentry_utils.ts";

initSentry();

serve(withSentry(async (req) => {
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

    // 2. Init IamportClient
    const impKey = Deno.env.get("PORTONE_API_KEY");
    const impSecret = Deno.env.get("PORTONE_API_SECRET");

    if (!impKey || !impSecret) {
      console.error("Missing Portone credentials");
      return errorResponse("Server configuration error", 500);
    }

    // 3. Cancel Payment via IamportClient
    const client = new IamportClient(impKey, impSecret);
    let cancelResponse: unknown;
    try {
      cancelResponse = await client.cancelPayment(
        payment_id,
        reason || "심사 반려로 인한 자동 환불",
      );
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error("Failed to cancel payment:", message);
      if (message.startsWith("Failed to get token") || message.startsWith("Iamport Error")) {
        return errorResponse("Payment provider error", 502);
      }
      return errorResponse(message, 400);
    }

    // 4. Success
    return successResponse({ success: true, data: cancelResponse });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in cancel-payment:", message);
    return errorResponse(message, 500);
  }
}));
