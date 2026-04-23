// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "../_shared/supabase_client.ts";
import { getPortoneClient } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireServiceRole } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "settlement-transfer";


initSentry();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  // Fix #1489: 벌크 금융 작업 — service_role 전용으로 전환, 일반 유저 접근 차단
  const auth = requireServiceRole(req);
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

    const supabase = createServiceClient();

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

    const portone = getPortoneClient();
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
