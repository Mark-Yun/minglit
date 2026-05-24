import {
  type InputResult,
  optionalStringField,
  requireStringField,
} from "../_shared/input_validation.ts";

export interface CancelOrderInput {
  event_id: string;
  reason?: string;
}

export function parseCancelOrderInput(
  body: Record<string, unknown>,
): InputResult<CancelOrderInput> {
  const eventId = requireStringField(body, "event_id");
  if (eventId instanceof Response) return eventId;

  const reason = optionalStringField(body, "reason");
  if (reason instanceof Response) return reason;

  return reason === undefined
    ? { event_id: eventId }
    : { event_id: eventId, reason };
}
