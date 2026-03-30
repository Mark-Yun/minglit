import { createServiceClient } from "../_shared/supabase_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";

const FN = "user-cancel-deletion";
const DELETION_GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000;

initSentry();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    const supabase = createServiceClient();

    const { data: profile, error: profileError } = await withSpan(
      "db.query.user_profiles",
      "db.query",
      async () =>
        await supabase
          .from("user_profiles")
          .select("deleted_at")
          .eq("id", userId)
          .single(),
    );

    if (profileError || !profile) {
      log({
        function: FN,
        level: "error",
        message: "Failed to fetch user profile",
        metadata: { detail: profileError, userId },
      });
      return errorResponse("User profile not found", 404);
    }

    if (!profile.deleted_at) {
      return errorResponse("탈퇴 진행 중인 계정이 아닙니다", 404);
    }

    const deletedAtMs = Date.parse(profile.deleted_at);
    if (Number.isNaN(deletedAtMs)) {
      log({
        function: FN,
        level: "error",
        message: "Invalid deleted_at timestamp",
        metadata: { deleted_at: profile.deleted_at, userId },
      });
      return errorResponse("Invalid deletion state", 500);
    }

    if (Date.now() - deletedAtMs >= DELETION_GRACE_PERIOD_MS) {
      return errorResponse("탈퇴 유예 기간이 만료되었습니다", 400);
    }

    const { error: updateError } = await withSpan(
      "db.update.user_profiles.restore",
      "db.update",
      async () =>
        await supabase
          .from("user_profiles")
          .update({
            deleted_at: null,
          })
          .eq("id", userId),
    );

    if (updateError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to restore deleted account",
        metadata: { detail: updateError, userId },
      });
      return errorResponse("Failed to cancel account deletion", 500);
    }

    return successResponse({ success: true });
  } catch (error) {
    log({
      function: FN,
      level: "error",
      message: "Unhandled error in user-cancel-deletion",
      metadata: { detail: error instanceof Error ? error.message : String(error), userId },
    });
    return errorResponse("Internal server error", 500);
  }
}));
