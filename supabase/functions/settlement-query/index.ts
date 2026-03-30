import { PortoneV2Client } from "../_shared/portone_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "settlement-query";

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

    const { partner_id, from_date, to_date, type } = reqBody as {
      partner_id?: string;
      from_date?: string;
      to_date?: string;
      type?: "settlements" | "payouts";
    };

    if (!type || (type !== "settlements" && type !== "payouts")) {
      return errorResponse("Missing or invalid type: must be 'settlements' or 'payouts'", 400);
    }

    const portone = new PortoneV2Client(PORTONE_V2_API_KEY);

    if (type === "settlements") {
      let result: Record<string, unknown>;
      try {
        result = await portone.getPartnerSettlements({
          partnerId: partner_id,
          dateRange: from_date || to_date ? { from: from_date, until: to_date } : undefined,
        });
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        log({ function: FN, level: "error", message: "PortOne getPartnerSettlements error", metadata: { detail: message } });
        return errorResponse("Failed to fetch settlements", 502);
      }
      return successResponse({ success: true, ...result });
    }

    let result: Record<string, unknown>;
    try {
      result = await portone.getPayouts({
        partnerId: partner_id,
      });
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      log({ function: FN, level: "error", message: "PortOne getPayouts error", metadata: { detail: message } });
      return errorResponse("Failed to fetch payouts", 502);
    }
    return successResponse({ success: true, ...result });

  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: "Error in settlement-query", metadata: { detail: message } });
    return errorResponse(message, 500);
  }
}));
