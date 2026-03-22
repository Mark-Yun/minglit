import { createClient } from "@supabase/supabase-js";
import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "partner-sync";

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

    const { partner_id } = reqBody as { partner_id?: string };
    if (!partner_id) {
      return errorResponse("Missing partner_id", 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: partner, error: partnerError } = await supabase
      .from("partners")
      .select("id, name, portone_partner_id")
      .eq("id", partner_id)
      .single();

    if (partnerError || !partner) {
      return errorResponse("Partner not found", 404);
    }

    if (partner.portone_partner_id) {
      return successResponse({ success: true, portone_partner_id: partner.portone_partner_id, skipped: true });
    }

    const portone = new PortoneV2Client(PORTONE_V2_API_KEY);
    let portonePartner: { id: string };
    try {
      portonePartner = await portone.createPartner({
        id: partner_id,
        name: partner.name,
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      log({ function: FN, level: "error", message: "PortOne createPartner error", metadata: { detail: message } });
      return errorResponse("Failed to create PortOne partner", 502);
    }

    const { error: updateError } = await supabase
      .from("partners")
      .update({ portone_partner_id: portonePartner.id })
      .eq("id", partner_id);

    if (updateError) {
      log({ function: FN, level: "error", message: "DB Update Error", metadata: { detail: updateError } });
      return errorResponse("Failed to save portone_partner_id", 500);
    }

    return successResponse({ success: true, portone_partner_id: portonePartner.id });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: "Error in partner-sync", metadata: { detail: message } });
    return errorResponse(message, 500);
  }
}));
