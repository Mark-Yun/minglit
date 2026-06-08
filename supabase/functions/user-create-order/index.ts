// Fix #2185 (Batch 5): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
import { initStatsig } from "../_shared/statsig_utils.ts";
import { createApplicationOrder } from "./create_order_service.ts";
import { parseCreateOrderInput } from "./input.ts";

const FN = "user-create-order";

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

    const input = parseCreateOrderInput(body);
    if (input instanceof Response) return input;

    const result = await createApplicationOrder({
      supabase: ctx.supabase,
      userId: ctx.auth.userId,
      input,
    });

    if (!result.ok) {
      return errorResponse(
        result.message,
        result.status,
        result.code ? { code: result.code } : undefined,
      );
    }

    return successResponse({
      success: true,
      application_id: result.applicationId,
      amount: result.amount,
      requires_payment: result.requiresPayment,
      ticket_name: result.ticketName,
      ...(result.payment ? { payment: result.payment } : {}),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "Error in user-create-order",
      metadata: { detail: message },
    });
    return errorResponse("주문 생성 중 오류가 발생했습니다.", 500);
  }
};

minglitEdgeFunction(handler);
