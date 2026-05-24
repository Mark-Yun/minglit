import { errorResponse } from "../_shared/response_utils.ts";

export interface CancelOrderInput {
  event_id: string;
  reason?: string;
}

export function parseCancelOrderInput(
  body: Record<string, unknown>,
): CancelOrderInput | Response {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || eventId.length === 0) {
    return errorResponse("Missing required field: event_id", 400);
  }

  const reason = body.reason;
  if (reason !== undefined && typeof reason !== "string") {
    return errorResponse("Invalid field: reason", 400);
  }

  return reason === undefined
    ? { event_id: eventId }
    : { event_id: eventId, reason };
}
