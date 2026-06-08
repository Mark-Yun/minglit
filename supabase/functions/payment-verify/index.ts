// Fix #2185 (Batch 8): migrate to minglitEdgeFunction wrapper — auth via manifest
// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { IamportClient } from "../_shared/iamport_client.ts";
import { getPortoneClient } from "../_shared/portone_client.ts";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";
import { initStatsig } from "../_shared/statsig_utils.ts";
import { parsePaymentVerifyInput } from "./input.ts";
import { verifyPayment } from "./verify_payment_service.ts";

const FN = "payment-verify";

const IMP_KEY = Deno.env.get("PORTONE_API_KEY");
const IMP_SECRET = Deno.env.get("PORTONE_API_SECRET");

if (!IMP_KEY || !IMP_SECRET) {
  throw new Error(
    "Missing required environment variables: PORTONE_API_KEY, PORTONE_API_SECRET",
  );
}

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

    const input = parsePaymentVerifyInput(body);
    if (input instanceof Response) return input;

    const result = await verifyPayment({
      supabase: ctx.supabase,
      userId: ctx.auth.userId,
      input,
      iamportClient: new IamportClient(IMP_KEY, IMP_SECRET),
      ...("provider" in input ? { portoneClient: getPortoneClient() } : {}),
    });

    if (!result.ok) {
      return errorResponse(result.message, result.status, result.details);
    }

    if (result.alreadyProcessed) {
      return successResponse({
        success: true,
        type: "already_processed",
        message: "Already processed",
        ...(result.applicationId
          ? { application_id: result.applicationId }
          : {}),
        ...(result.applicationId
          ? { purchase_url: `/my/purchases?purchase=${result.applicationId}` }
          : {}),
      });
    }

    return successResponse({
      success: true,
      type: "paid",
      ...(result.impUid ? { imp_uid: result.impUid } : {}),
      ...(result.paymentId ? { payment_id: result.paymentId } : {}),
      application_id: result.applicationId,
      purchase_url: `/my/purchases?purchase=${result.applicationId}`,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "Error in payment-verify",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
