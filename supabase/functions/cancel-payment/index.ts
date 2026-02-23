import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
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
    const { payment_id, reason, amount, checksum } = reqBody as {
      payment_id?: string;
      reason?: string;
      amount?: number;
      checksum?: number;
    };

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
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );
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
    console.error("Error in cancel-payment:", message);
    return errorResponse(message, 500);
  }
}));
