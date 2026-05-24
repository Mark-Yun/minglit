import {
  type InputResult,
  requireStringField,
} from "../_shared/input_validation.ts";

export interface PaymentVerifyInput {
  imp_uid: string;
  merchant_uid: string;
}

export function parsePaymentVerifyInput(
  body: Record<string, unknown>,
): InputResult<PaymentVerifyInput> {
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
