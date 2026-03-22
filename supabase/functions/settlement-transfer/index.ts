// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createClient } from "@supabase/supabase-js";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "settlement-transfer";

const PORTONE_V2_API_KEY = Deno.env.get("PORTONE_V2_API_KEY");

if (!PORTONE_V2_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

initSentry();

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
      log({ function: FN, level: "error", message: "PortOne createOrderTransfer error", metadata: { detail: message } });
      return errorResponse("Failed to create order transfer", 502);
    }

    return successResponse({ success: true, transfer });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: "Error in settlement-transfer", metadata: { detail: message } });
    return errorResponse(message, 500);
  }
}));
