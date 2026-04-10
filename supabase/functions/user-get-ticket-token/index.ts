// user-get-ticket-token/index.ts — Issue a signed ticket token for QR display
// Fix #1206: QR screen now fetches token from Edge Function if not in local wallet

import { createServiceClient } from "../_shared/supabase_client.ts";
import { corsResponse, errorResponse, successResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, log } from "../_shared/logger.ts";

const FN = "user-get-ticket-token";

initSentry();

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const authUid = auth;

  let reqBody: Record<string, unknown>;
  try {
    reqBody = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { ticket_id } = reqBody as { ticket_id?: string };

  if (!ticket_id) {
    return errorResponse("Missing required parameter: ticket_id", 400);
  }

  const supabase = createServiceClient();

  // Verify the user has a paid/approved application for this ticket
  const { data: application, error: appErr } = await supabase
    .from("event_applications")
    .select("ticket_id, event_id, user_id, status")
    .eq("user_id", authUid)
    .eq("ticket_id", ticket_id)
    .in("status", ["paid", "approved"])
    .maybeSingle();

  if (appErr) {
    log({ function: FN, level: "error", message: "Failed to fetch application", metadata: { detail: appErr.message } });
    return errorResponse("Failed to fetch application", 500);
  }

  if (!application) {
    return errorResponse("Ticket not found", 404);
  }

  const eventId = (application as { event_id: string }).event_id;

  // Read the signing key from environment
  const privateKeyJwkStr = Deno.env.get("TICKET_SIGNING_PRIVATE_KEY_JWK");
  if (!privateKeyJwkStr) {
    log({ function: FN, level: "error", message: "TICKET_SIGNING_PRIVATE_KEY_JWK not configured" });
    return errorResponse("Ticket signing key not configured", 500);
  }

  let privateKey: CryptoKey;
  try {
    privateKey = await crypto.subtle.importKey(
      "jwk",
      JSON.parse(privateKeyJwkStr),
      { name: "Ed25519" },
      false,
      ["sign"],
    );
  } catch (e) {
    log({ function: FN, level: "error", message: "Failed to import signing key", metadata: { detail: String(e) } });
    return errorResponse("Failed to import signing key", 500);
  }

  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  const payload = `${ticket_id}|${eventId}|${authUid}|${expiresAt.toISOString()}`;
  const message = new TextEncoder().encode(payload);

  let sigBytes: ArrayBuffer;
  try {
    sigBytes = await crypto.subtle.sign("Ed25519", privateKey, message);
  } catch (e) {
    log({ function: FN, level: "error", message: "Failed to sign ticket token", metadata: { detail: String(e) } });
    return errorResponse("Failed to sign ticket token", 500);
  }

  const signature = base64UrlEncode(new Uint8Array(sigBytes));

  log({ function: FN, level: "info", message: "Ticket token issued", metadata: { ticket_id, event_id: eventId } });

  return successResponse({
    ticket_id,
    event_id: eventId,
    user_id: authUid,
    signature,
    expires_at: expiresAt.toISOString(),
  });
}));
