import { getPortoneClient } from "../_shared/portone_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";

const FN = "settlement-query";

export const handler = async (req: Request, { auth, supabase }: EFContext): Promise<Response> => {
  if (auth.type !== "user") return errorResponse("Unexpected auth type", 500);
  const userId = auth.userId;

  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const { partner_id, from_date, to_date, type } = body as {
      partner_id?: string;
      from_date?: string;
      to_date?: string;
      type?: "settlements" | "payouts";
    };

    if (!type || (type !== "settlements" && type !== "payouts")) {
      return errorResponse(
        "Missing or invalid type: must be 'settlements' or 'payouts'",
        400,
      );
    }
    const partnerId = typeof partner_id === "string" ? partner_id.trim() : "";
    if (!partnerId) return errorResponse("Missing partner_id", 400);

    const permCheck = await requirePartnerPermission(
      supabase,
      partnerId,
      userId,
      ["SETTLEMENT_VIEW"],
    );
    if (permCheck) return permCheck;

    const { data: partner, error: partnerError } = await supabase
      .from("partners")
      .select("portone_partner_id")
      .eq("id", partnerId)
      .single();

    if (partnerError || !partner) {
      return errorResponse("Partner not found", 404);
    }

    if (!partner.portone_partner_id) {
      return errorResponse("Partner not synced with PortOne", 400);
    }

    const portone = getPortoneClient();
    const portonePartnerId = partner.portone_partner_id;

    if (type === "settlements") {
      let result: Record<string, unknown>;
      try {
        result = await portone.getPartnerSettlements({
          partnerId: portonePartnerId,
          dateRange: from_date || to_date
            ? { from: from_date, until: to_date }
            : undefined,
        });
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        log({
          function: FN,
          level: "error",
          message: "PortOne getPartnerSettlements error",
          metadata: { detail: message },
        });
        return errorResponse("Failed to fetch settlements", 502);
      }
      return successResponse({ success: true, ...result });
    }

    let result: Record<string, unknown>;
    try {
      result = await portone.getPayouts({
        partnerId: portonePartnerId,
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      log({
        function: FN,
        level: "error",
        message: "PortOne getPayouts error",
        metadata: { detail: message },
      });
      return errorResponse("Failed to fetch payouts", 502);
    }
    return successResponse({ success: true, ...result });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: "Error in settlement-query",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
