import { errorResponse } from "../_shared/response_utils.ts";

export interface PaymentVerifyInput {
  imp_uid: string;
  merchant_uid: string;
}

export function parsePaymentVerifyInput(
  body: Record<string, unknown>,
): PaymentVerifyInput | Response {
  const impUid = body.imp_uid;
  const merchantUid = body.merchant_uid;

  if (
    typeof impUid !== "string" ||
    impUid.length === 0 ||
    typeof merchantUid !== "string" ||
    merchantUid.length === 0
  ) {
    return errorResponse("Missing required parameters", 400);
  }

  return { imp_uid: impUid, merchant_uid: merchantUid };
}
