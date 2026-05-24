import {
  type InputResult,
  requireUuidField,
} from "../_shared/input_validation.ts";
import { errorResponse } from "../_shared/response_utils.ts";

export type PartnerApproveInput =
  | { action: "approve"; applicationId: string }
  | { action: "bulk_approve"; eventId: string };

export function parsePartnerApproveInput(
  action: string,
  body: Record<string, unknown>,
): InputResult<PartnerApproveInput> {
  if (action === "approve") {
    const applicationId = requireUuidField(body, "application_id", {
      missing: "Missing application_id",
      invalid: "Invalid application_id",
    });
    if (applicationId instanceof Response) return applicationId;
    return { action, applicationId };
  }

  if (action === "bulk_approve") {
    const eventId = requireUuidField(body, "event_id", {
      missing: "Missing event_id",
      invalid: "Invalid event_id",
    });
    if (eventId instanceof Response) return eventId;
    return { action, eventId };
  }

  return errorResponse(`Unknown action: ${action}`, 400);
}
