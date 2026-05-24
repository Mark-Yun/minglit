// Fix #2185 (Batch 5): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
import { initStatsig } from "../_shared/statsig_utils.ts";
import { cancelOrder } from "./cancel_order_service.ts";
import { parseCancelOrderInput } from "./input.ts";

const FN = "user-cancel-order";

initStatsig();

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (ctx.auth.type !== "user") {
    return errorResponse("Unexpected auth type", 500);
  }

  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const input = parseCancelOrderInput(body);
    if (input instanceof Response) return input;

    const result = await cancelOrder({
      supabase: ctx.supabase,
      userId: ctx.auth.userId,
      input,
    });

    if (!result.ok) {
      return errorResponse(result.message, result.status, result.details);
    }

    if (result.type === "refunded") {
      return successResponse({
        success: true,
        type: "refunded",
        data: { refund_amount: result.refundAmount },
      });
    }

    return successResponse({ success: true, type: "cancelled" });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: `Error in user-cancel-order: ${message}`,
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
