import {
  type InputResult,
  optionalStringField,
  requireStringField,
} from "../_shared/input_validation.ts";
import { errorResponse } from "../_shared/response_utils.ts";

export type RefundRequestReasonCode = "schedule_change" | "health" | "other";

export interface UserRequestRefundInput {
  application_id: string;
  reason_code: RefundRequestReasonCode;
  reason_text?: string;
}

const REASON_CODES = new Set(["schedule_change", "health", "other"]);

export function parseUserRequestRefundInput(
  body: Record<string, unknown>,
): InputResult<UserRequestRefundInput> {
  const applicationId = requireStringField(body, "application_id");
  if (applicationId instanceof Response) return applicationId;

  const reasonCode = requireStringField(body, "reason_code");
  if (reasonCode instanceof Response) return reasonCode;
  if (!REASON_CODES.has(reasonCode)) {
    return errorResponse("Invalid field: reason_code", 400);
  }

  const reasonText = optionalStringField(body, "reason_text");
  if (reasonText instanceof Response) return reasonText;

  return reasonText === undefined
    ? {
      application_id: applicationId,
      reason_code: reasonCode as RefundRequestReasonCode,
    }
    : {
      application_id: applicationId,
      reason_code: reasonCode as RefundRequestReasonCode,
      reason_text: reasonText,
    };
}
