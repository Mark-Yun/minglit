import { createClient } from "@supabase/supabase-js";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-create-order";

initSentry();
initStatsig();

// Error code → HTTP status mapping
const ERROR_STATUS: Record<string, number> = {
  EVENT_NOT_FOUND: 404,
  TICKET_NOT_FOUND: 404,
  ALREADY_APPLIED: 409,
  EVENT_NOT_ACTIVE: 400,
  EVENT_FULL: 400,
  TICKET_SOLD_OUT: 400,
  IDENTITY_REQUIRED: 400,
  ELIGIBILITY_FAILED: 400,
  VERIFICATION_REQUIRED: 400,
  BALANCE_LIMIT: 400,
};

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { event_id, ticket_id } = body as { event_id?: string; ticket_id?: string };

    if (!event_id || !ticket_id) {
      return errorResponse("Missing required parameters: event_id, ticket_id", 400);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: result, error: rpcError } = await supabase.rpc(
      "create_order_validated",
      {
        p_event_id: event_id,
        p_ticket_id: ticket_id,
        p_user_id: userId,
      },
    );

    if (rpcError) {
      console.error("RPC error:", rpcError);
      return errorResponse("Internal server error", 500);
    }

    const payload = result as Record<string, unknown>;

    if (payload.error) {
      const code = payload.error as string;
      const status = ERROR_STATUS[code] ?? 400;
      return errorResponse(code, status, payload.reason ? { reason: payload.reason } : undefined);
    }

    return successResponse({
      success: true,
      application_id: payload.application_id,
      amount: payload.amount,
      requires_payment: payload.requires_payment,
      ticket_name: payload.ticket_name,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("Error in user-create-order:", message);
    return errorResponse(message, 500);
  }
}));
