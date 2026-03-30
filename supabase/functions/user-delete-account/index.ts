import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, log, withHandler, withSpan } from "../_shared/logger.ts";

const FN = "user-delete-account";
const GRACE_PERIOD_DAYS = 7;
const ACTIVE_BOOKING_STATUSES = [
  "pending",
  "pending_review",
  "approved",
  "paid",
  "payment_pending",
];

type DeleteAccountRequest = {
  reason_code?: unknown;
  reason_text?: unknown;
};

initSentry();

async function parseRequestBody(
  req: Request,
): Promise<DeleteAccountRequest | Response> {
  const raw = await req.text();
  if (!raw.trim()) {
    return {};
  }

  try {
    return JSON.parse(raw) as DeleteAccountRequest;
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method Not Allowed", 405);

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    const body = await parseRequestBody(req);
    if (body instanceof Response) return body;

    const reasonCode = typeof body.reason_code === "string"
      ? body.reason_code.trim()
      : undefined;
    const reasonText = typeof body.reason_text === "string"
      ? body.reason_text.trim()
      : undefined;

    if (body.reason_code !== undefined && !reasonCode) {
      return errorResponse("reason_code must be a non-empty string", 400);
    }
    if (
      body.reason_text !== undefined && typeof body.reason_text !== "string"
    ) {
      return errorResponse("reason_text must be a string", 400);
    }
    if (reasonText && reasonText.length > 200) {
      return errorResponse("reason_text must be 200 characters or fewer", 400);
    }

    const supabase = createServiceClient();
    const now = new Date();
    const nowIso = now.toISOString();
    const gracePeriodEnds = new Date(
      now.getTime() + GRACE_PERIOD_DAYS * 24 * 60 * 60 * 1000,
    ).toISOString();

    const { data: userProfiles, error: userError } = await withSpan(
      "db.query.user_profiles",
      "db.query",
      () =>
        supabase
          .from("user_profiles")
          .select("deleted_at")
          .eq("id", userId)
          .limit(1),
    );

    if (userError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to load user profile",
        metadata: { detail: userError, userId },
      });
      return errorResponse("Failed to load user profile", 500);
    }

    const userProfile = userProfiles?.[0] as
      | { deleted_at?: string | null }
      | undefined;
    if (!userProfile) {
      return errorResponse("User profile not found", 404);
    }
    if (userProfile.deleted_at) {
      return errorResponse("Account deletion already pending", 409);
    }

    const { data: activeBookings, error: bookingError } = await withSpan(
      "db.query.active_bookings",
      "db.query",
      () =>
        supabase
          .from("event_applications")
          .select("id, events!inner(start_time, status)")
          .eq("user_id", userId)
          .in("status", ACTIVE_BOOKING_STATUSES)
          .eq("events.status", "scheduled")
          .gte("events.start_time", nowIso)
          .limit(1),
    );

    if (bookingError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to load active bookings",
        metadata: { detail: bookingError, userId },
      });
      return errorResponse("Failed to verify active bookings", 500);
    }
    if ((activeBookings?.length ?? 0) > 0) {
      return errorResponse(
        "Active bookings must be cancelled before deleting account",
        400,
      );
    }

    const { data: pendingRefunds, error: refundError } = await withSpan(
      "db.query.pending_refunds",
      "db.query",
      () =>
        supabase
          .from("event_applications")
          .select("id")
          .eq("user_id", userId)
          .eq("refund_status", "requested")
          .limit(1),
    );

    if (refundError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to load unsettled refunds",
        metadata: { detail: refundError, userId },
      });
      return errorResponse("Failed to verify unsettled balance", 500);
    }
    if ((pendingRefunds?.length ?? 0) > 0) {
      return errorResponse(
        "Unsettled balance must be resolved before deleting account",
        400,
      );
    }

    const { error: updateError } = await withSpan(
      "db.update.user_profiles.deleted_at",
      "db.update",
      () =>
        supabase
          .from("user_profiles")
          .update({
            deleted_at: nowIso,
            updated_at: nowIso,
          })
          .eq("id", userId)
          .is("deleted_at", null),
    );

    if (updateError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to mark account as deleted",
        metadata: { detail: updateError, userId },
      });
      return errorResponse("Failed to delete account", 500);
    }

    if (reasonCode || reasonText) {
      const { error: reasonError } = await withSpan(
        "db.insert.withdrawal_reasons",
        "db.insert",
        () =>
          supabase
            .from("withdrawal_reasons")
            .insert({
              reason_code: reasonCode ?? "other",
              reason_text: reasonText ?? null,
            }),
      );

      if (reasonError) {
        log({
          function: FN,
          level: "error",
          message: "Failed to save withdrawal reason",
          metadata: { detail: reasonError, userId },
        });
        return errorResponse("Failed to save withdrawal reason", 500);
      }
    }

    const { error: tokenDeleteError } = await withSpan(
      "db.delete.fcm_tokens",
      "db.delete",
      () =>
        supabase
          .from("fcm_tokens")
          .delete()
          .eq("user_id", userId),
    );

    if (tokenDeleteError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to delete FCM tokens",
        metadata: { detail: tokenDeleteError, userId },
      });
      return errorResponse("Failed to unsubscribe push notifications", 500);
    }

    return successResponse({
      success: true,
      grace_period_ends: gracePeriodEnds,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: `Error in ${FN}: ${message}`,
    });
    return errorResponse(message, 500);
  }
}));
