import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { withSpan, log } from "../_shared/logger.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

const FN = "user-cancel-deletion";
const DELETION_GRACE_PERIOD_MS = 7 * 24 * 60 * 60 * 1000;

export const handler = async (req: Request, { auth, supabase }: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { userId } = auth as { type: "user"; userId: string };

  try {
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
};

minglitEdgeFunction(handler);
