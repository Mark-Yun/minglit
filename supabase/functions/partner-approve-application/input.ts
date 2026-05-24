import { errorResponse } from "../_shared/response_utils.ts";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export type PartnerApproveInput =
  | { action: "approve"; applicationId: string }
  | { action: "bulk_approve"; eventId: string };

export function parsePartnerApproveInput(
  action: string,
  body: Record<string, unknown>,
): PartnerApproveInput | Response {
  if (action === "approve") {
    const applicationId = body.application_id;
    if (typeof applicationId !== "string" || !applicationId) {
      return errorResponse("Missing application_id", 400);
    }
    if (!UUID_RE.test(applicationId)) {
      return errorResponse("Invalid application_id", 400);
    }
    return { action, applicationId };
  }

  if (action === "bulk_approve") {
    const eventId = body.event_id;
    if (typeof eventId !== "string" || !eventId) {
      return errorResponse("Missing event_id", 400);
    }
    if (!UUID_RE.test(eventId)) {
      return errorResponse("Invalid event_id", 400);
    }
    return { action, eventId };
  }

  return errorResponse(`Unknown action: ${action}`, 400);
}
