import type { CreateOrderVerificationData } from "../_shared/domains/order/create_order_policy.ts";
import {
  type InputResult,
  isPlainRecord,
  requireStringField,
} from "../_shared/input_validation.ts";
import { errorResponse } from "../_shared/response_utils.ts";

export interface CreateOrderInput {
  event_id: string;
  ticket_id: string;
  verification_data?: CreateOrderVerificationData;
}

export function parseCreateOrderInput(
  body: Record<string, unknown>,
): InputResult<CreateOrderInput> {
  const eventId = requireStringField(body, "event_id");
  if (eventId instanceof Response) return eventId;

  const ticketId = requireStringField(body, "ticket_id");
  if (ticketId instanceof Response) return ticketId;

  const verificationData = body.verification_data;
  if (verificationData === undefined) {
    return { event_id: eventId, ticket_id: ticketId };
  }

  if (!isVerificationData(verificationData)) {
    return errorResponse("Invalid field: verification_data", 400);
  }

  return {
    event_id: eventId,
    ticket_id: ticketId,
    verification_data: verificationData,
  };
}

function isVerificationData(
  value: unknown,
): value is CreateOrderVerificationData {
  if (!isPlainRecord(value)) return false;
  const record = value;
  const data = record.data;
  return typeof record.verification_id === "string" &&
    isPlainRecord(data);
}
