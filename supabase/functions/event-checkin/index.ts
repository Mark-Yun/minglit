// event-checkin/index.ts — Check-in a participant for an event

import { createServiceClient } from "../_shared/supabase_client.ts";
import { corsResponse, errorResponse, successResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "event-checkin";

initSentry();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  let reqBody: Record<string, unknown>;
  try {
    reqBody = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { event_id, participant_id } = reqBody as {
    event_id?: string;
    participant_id?: string;
  };

  if (!event_id || !participant_id) {
    return errorResponse("Missing required parameters: event_id, participant_id", 400);
  }

  const supabase = createServiceClient();

  // Fetch the participant row to validate ownership and current status
  const { data: participant, error: fetchErr } = await supabase
    .from("event_participants")
    .select("id, event_id, user_id, status")
    .eq("id", participant_id)
    .eq("event_id", event_id)
    .maybeSingle();

  if (fetchErr) {
    log({ function: FN, level: "error", message: "Failed to fetch participant", metadata: { detail: fetchErr.message } });
    return errorResponse("Failed to fetch participant", 500);
  }

  if (!participant) {
    return errorResponse("Participant not found", 404);
  }

  // Validate caller is the participant's user
  if ((participant as { user_id: string }).user_id !== auth) {
    return errorResponse("Forbidden: caller is not the participant's user", 403);
  }

  // Fix #998: 이벤트 상태 머신 확장 — active/ongoing 상태에서만 체크인 허용
  const { data: event, error: eventFetchErr } = await supabase
    .from("events")
    .select("id, status")
    .eq("id", event_id)
    .maybeSingle();

  if (eventFetchErr) {
    log({ function: FN, level: "error", message: "Failed to fetch event", metadata: { detail: eventFetchErr.message } });
    return errorResponse("Failed to fetch event", 500);
  }

  if (!event) {
    return errorResponse("Event not found", 404);
  }

  const eventStatus = (event as { status: string }).status;
  if (eventStatus !== "active" && eventStatus !== "ongoing") {
    return errorResponse("체크인은 active 또는 ongoing 상태의 이벤트에서만 가능합니다", 400);
  }

  const currentStatus = (participant as { status: string }).status;

  if (currentStatus === "checked_in") {
    return errorResponse("Participant already checked in", 409);
  }

  if (currentStatus !== "ticket_issued") {
    return errorResponse(`Cannot check in participant with status '${currentStatus}'`, 400);
  }

  // Transition status: ticket_issued → checked_in
  const { error: updateErr, count } = await supabase
    .from("event_participants")
    .update({ status: "checked_in" }, { count: "exact" })
    .eq("id", participant_id)
    .eq("status", "ticket_issued");

  if (updateErr) {
    log({ function: FN, level: "error", message: "Failed to update participant status", metadata: { detail: updateErr.message } });
    return errorResponse("Failed to check in participant", 500);
  }

  if ((count ?? 0) === 0) {
    return errorResponse("Participant status changed concurrently, please retry", 409);
  }

  log({ function: FN, level: "info", message: "Participant checked in", metadata: { participant_id, event_id } });

  return successResponse({
    success: true,
    participant_id,
    status: "checked_in",
  });
}));
