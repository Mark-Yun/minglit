import {
  type InputResult,
  requireStringField,
} from "../_shared/input_validation.ts";

export interface PaymentVerifyInput {
  imp_uid: string;
  merchant_uid: string;
}

export interface PaymentVerifyV2Input {
  provider: "portone_v2";
  payment_id: string;
}

export type PaymentVerifyAnyInput = PaymentVerifyInput | PaymentVerifyV2Input;

export function parsePaymentVerifyInput(
  body: Record<string, unknown>,
): InputResult<PaymentVerifyAnyInput> {
  if (body.provider === "portone_v2") {
    const paymentId = requireStringField(
      body,
      "payment_id",
      "Missing required parameters",
    );
    if (paymentId instanceof Response) return paymentId;
    return { provider: "portone_v2", payment_id: paymentId };
  }

  const impUid = requireStringField(
    body,
    "imp_uid",
    "Missing required parameters",
  );
  if (impUid instanceof Response) return impUid;

  const merchantUid = requireStringField(
    body,
    "merchant_uid",
    "Missing required parameters",
  );
  if (merchantUid instanceof Response) return merchantUid;

  return { imp_uid: impUid, merchant_uid: merchantUid };
}
