import { errorResponse } from "../_shared/response_utils.ts";
import type { CreateOrderVerificationData } from "../_shared/domains/order/create_order_policy.ts";

export interface CreateOrderInput {
  event_id: string;
  ticket_id: string;
  verification_data?: CreateOrderVerificationData;
}

export function parseCreateOrderInput(
  body: Record<string, unknown>,
): CreateOrderInput | Response {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || eventId.length === 0) {
    return errorResponse("Missing required field: event_id", 400);
  }

  const ticketId = body.ticket_id;
  if (typeof ticketId !== "string" || ticketId.length === 0) {
    return errorResponse("Missing required field: ticket_id", 400);
  }

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
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return false;
  }
  const record = value as Record<string, unknown>;
  const data = record.data;
  return typeof record.verification_id === "string" &&
    typeof data === "object" &&
    data !== null &&
    !Array.isArray(data);
}
