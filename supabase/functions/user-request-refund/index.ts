import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { log } from "../_shared/logger.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { parseUserRequestRefundInput } from "./input.ts";
import { requestPartnerRefund } from "./request_refund_service.ts";

const FN = "user-request-refund";

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

    const input = parseUserRequestRefundInput(body);
    if (input instanceof Response) return input;

    const result = await requestPartnerRefund({
      supabase: ctx.supabase,
      userId: ctx.auth.userId,
      input,
    });

    if (!result.ok) {
      return errorResponse(result.message, result.status, result.details);
    }

    return successResponse({
      success: true,
      type: "partner_refund_requested",
      request: result.request,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "Error in user-request-refund",
      metadata: { detail: message },
    });
    return errorResponse("환불 요청 중 오류가 발생했습니다.", 500);
  }
};

minglitEdgeFunction(handler);
