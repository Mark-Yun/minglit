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
      console.error("PortOne createPartner error:", message);
      return errorResponse("Failed to create PortOne partner", 502);
    }

    const { error: updateError } = await supabase
      .from("partners")
      .update({ portone_partner_id: portonePartner.id })
      .eq("id", partner_id);

    if (updateError) {
      console.error("DB Update Error:", updateError);
      return errorResponse("Failed to save portone_partner_id", 500);
    }

    return successResponse({ success: true, portone_partner_id: portonePartner.id });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Error in sync-platform-partner:", message);
    return errorResponse(message, 500);
  }
}));
