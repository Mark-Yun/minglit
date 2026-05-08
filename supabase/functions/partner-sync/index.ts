// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
// Fix #2185 (Batch 7): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { getPortoneClient } from "../_shared/portone_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";

const FN = "partner-sync";

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  const { supabase } = ctx;
  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const { partner_id } = body as { partner_id?: string };
    if (!partner_id) {
      return errorResponse("Missing partner_id", 400);
    }

    const { data: partner, error: partnerError } = await supabase
      .from("partners")
      .select("id, name, portone_partner_id")
      .eq("id", partner_id)
      .single();

    if (partnerError || !partner) {
      return errorResponse("Partner not found", 404);
    }

    if (partner.portone_partner_id) {
      return successResponse({
        success: true,
        portone_partner_id: partner.portone_partner_id,
        skipped: true,
      });
    }

    const portone = getPortoneClient();
    let portonePartner: { id: string };
    try {
      portonePartner = await portone.createPartner({
        id: partner_id,
        name: partner.name,
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      log({
        function: FN,
        level: "error",
        message: "PortOne createPartner error",
        metadata: { detail: message },
      });
      return errorResponse("Failed to create PortOne partner", 502);
    }

    const { error: updateError } = await supabase
      .from("partners")
      .update({ portone_partner_id: portonePartner.id })
      .eq("id", partner_id);

    if (updateError) {
      log({
        function: FN,
        level: "error",
        message: "DB Update Error",
        metadata: { detail: updateError },
      });
      return errorResponse("Failed to save portone_partner_id", 500);
    }

    return successResponse({
      success: true,
      portone_partner_id: portonePartner.id,
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: "Error in partner-sync",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
