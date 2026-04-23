// event-checkin/index.ts — Check-in a participant for an event

import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { initSentry, log, withHandler } from "../_shared/logger.ts";

const FN = "event-checkin";

initSentry();

// Fix #1491: base64url 디코딩 — Ed25519 서명 바이트 복원
function base64UrlDecode(str: string): Uint8Array {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/");
  const padding = (4 - (padded.length % 4)) % 4;
  const base64 = padded + "=".repeat(padding);
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;

  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const { event_id, participant_id, signature, expires_at } = body as {
    event_id?: string;
    participant_id?: string;
    signature?: string;
    expires_at?: string;
  };

  if (!event_id || !participant_id) {
    return errorResponse(
      "Missing required parameters: event_id, participant_id",
      400,
    );
  }

  // Fix #1491: QR 서명 검증을 위한 파라미터 — signature/expires_at이 없으면 요청 거부
  if (!signature || !expires_at) {
    return errorResponse(
      "Missing required parameters: signature, expires_at",
      400,
    );
  }

  // Fix #1491: expires_at 만료 확인
  const expiresAtMs = new Date(expires_at).getTime();
  if (isNaN(expiresAtMs) || expiresAtMs < Date.now()) {
    return errorResponse("QR token expired", 400);
  }

  const supabase = createServiceClient();

  // Fetch the participant row to validate ownership and current status
  const { data: participant, error: fetchErr } = await supabase
    .from("event_participants")
    .select("id, event_id, user_id, ticket_id, status")
    .eq("id", participant_id)
    .eq("event_id", event_id)
    .maybeSingle();

  if (fetchErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch participant",
      metadata: { detail: fetchErr.message },
    });
    return errorResponse("Failed to fetch participant", 500);
  }

  if (!participant) {
    return errorResponse("Participant not found", 404);
  }

  // Validate caller is the participant's user
  if ((participant as { user_id: string }).user_id !== auth) {
    return errorResponse(
      "Forbidden: caller is not the participant's user",
      403,
    );
  }

  // Fix #1491: 서버 측 Ed25519 QR 서명 검증 — 클라이언트 우회 방지
  const publicKeyJwkStr = Deno.env.get("TICKET_SIGNING_PUBLIC_KEY_JWK");
  if (!publicKeyJwkStr) {
    log({
      function: FN,
      level: "error",
      message: "TICKET_SIGNING_PUBLIC_KEY_JWK not configured",
    });
    return errorResponse("Ticket verification key not configured", 500);
  }

  try {
    const publicKey = await crypto.subtle.importKey(
      "jwk",
      JSON.parse(publicKeyJwkStr),
      { name: "Ed25519" },
      false,
      ["verify"],
    );

    const ticketId = (participant as { ticket_id: string }).ticket_id;
    const userId = (participant as { user_id: string }).user_id;
    const payload = `${ticketId}|${event_id}|${userId}|${expires_at}`;
    const message = new TextEncoder().encode(payload);
    const sigBytes = base64UrlDecode(signature);

    const valid = await crypto.subtle.verify(
      "Ed25519",
      publicKey,
      sigBytes,
      message,
    );
    if (!valid) {
      log({
        function: FN,
        level: "warn",
        message: "QR signature verification failed",
        metadata: { participant_id, event_id },
      });
      return errorResponse("Invalid QR signature", 403);
    }
  } catch (e) {
    log({
      function: FN,
      level: "error",
      message: "Signature verification error",
      metadata: { detail: String(e) },
    });
    return errorResponse("Signature verification failed", 500);
  }

  // Fix #998: 이벤트 상태 머신 확장 — active/ongoing 상태에서만 체크인 허용
  const { data: event, error: eventFetchErr } = await supabase
    .from("events")
    .select("id, status")
    .eq("id", event_id)
    .maybeSingle();

  if (eventFetchErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch event",
      metadata: { detail: eventFetchErr.message },
    });
    return errorResponse("Failed to fetch event", 500);
  }

  if (!event) {
    return errorResponse("Event not found", 404);
  }

  const eventStatus = (event as { status: string }).status;
  if (eventStatus !== "active" && eventStatus !== "ongoing") {
    return errorResponse(
      "체크인은 active 또는 ongoing 상태의 이벤트에서만 가능합니다",
      400,
    );
  }

  const currentStatus = (participant as { status: string }).status;

  if (currentStatus === "checked_in") {
    return errorResponse("Participant already checked in", 409);
  }

  if (currentStatus !== "ticket_issued") {
    return errorResponse(
      `Cannot check in participant with status '${currentStatus}'`,
      400,
    );
  }

  // Transition status: ticket_issued → checked_in
  const { error: updateErr, count } = await supabase
    .from("event_participants")
    .update({ status: "checked_in" }, { count: "exact" })
    .eq("id", participant_id)
    .eq("status", "ticket_issued");

  if (updateErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to update participant status",
      metadata: { detail: updateErr.message },
    });
    return errorResponse("Failed to check in participant", 500);
  }

  if ((count ?? 0) === 0) {
    return errorResponse(
      "Participant status changed concurrently, please retry",
      409,
    );
  }

  log({
    function: FN,
    level: "info",
    message: "Participant checked in",
    metadata: { participant_id, event_id },
  });

  return successResponse({
    success: true,
    participant_id,
    status: "checked_in",
  });
}));
