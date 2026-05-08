// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { getPortoneClient } from "../_shared/portone_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
// Fix #2185 (Batch 2): migrate to minglitEdgeFunction wrapper — auth via manifest (system caller)
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

const FN = "settlement-transfer";

export const handler = async (req: Request, { supabase }: EFContext): Promise<Response> => {
  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const { partner_id, payment_id, order_amount, settlement_date } = body as {
      partner_id?: string;
      payment_id?: string;
      order_amount?: number;
      settlement_date?: string;
    };

    if (!partner_id || !payment_id || order_amount === undefined) {
      return errorResponse(
        "Missing required fields: partner_id, payment_id, order_amount",
        400,
      );
    }

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
      transfer = await portone.createOrderTransfer(
        transferBody as Parameters<typeof portone.createOrderTransfer>[0],
      );
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      log({
        function: FN,
        level: "error",
        message: "PortOne createOrderTransfer error",
        metadata: { detail: message },
      });
      return errorResponse("Failed to create order transfer", 502);
    }

    return successResponse({ success: true, transfer });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: "Error in settlement-transfer",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
