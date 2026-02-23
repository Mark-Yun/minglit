import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { initSentry, withSentry } from "../_shared/sentry_utils.ts";

const PORTONE_V2_API_KEY = Deno.env.get("PORTONE_V2_API_KEY");

if (!PORTONE_V2_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

initSentry();

serve(withSentry(async (req) => {
  try {
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { partner_id, payment_id, order_amount, settlement_date } = reqBody as {
      partner_id?: string;
      payment_id?: string;
      order_amount?: number;
      settlement_date?: string;
    };

    if (!partner_id || !payment_id || order_amount === undefined) {
      return errorResponse("Missing required fields: partner_id, payment_id, order_amount", 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: partner, error: partnerError } = await supabase
      .from("partners")
      .select("portone_partner_id")
      .eq("id", partner_id)
      .single();

    if (partnerError || !partner) {
      return errorResponse("Partner not found", 404);
    }

    if (!partner.portone_partner_id) {
      return errorResponse("Partner not synced with PortOne", 400);
    }

    const portone = new PortoneV2Client(PORTONE_V2_API_KEY);
    const transferBody: Record<string, unknown> = {
      partnerId: partner.portone_partner_id,
      paymentId: payment_id,
      orderDetail: { orderAmount: order_amount },
    };
    if (settlement_date) {
      transferBody.settlementDate = settlement_date;
    }

    let transfer: Record<string, unknown>;
    try {
      transfer = await portone.createOrderTransfer(transferBody as Parameters<typeof portone.createOrderTransfer>[0]);
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      console.error("PortOne createOrderTransfer error:", message);
      return errorResponse("Failed to create order transfer", 502);
    }

    return successResponse({ success: true, transfer });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in create-order-transfer:", message);
    return errorResponse(message, 500);
  }
}));
