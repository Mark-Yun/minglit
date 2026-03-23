import { createServiceClient } from "../_shared/supabase_client.ts";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-update-verification";

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { verification_id, data } = reqBody as {
      verification_id?: string;
      data?: Record<string, unknown>;
    };

    if (!verification_id) {
      return errorResponse("Missing required field: verification_id", 400);
    }
    if (!data || typeof data !== "object") {
      return errorResponse("Missing required field: data", 400);
    }

    const supabase = createServiceClient();

    // Verify that the verification definition exists
    const { data: verification, error: verificationError } = await withSpan(
      "db.select.verifications", "db.select",
      () => supabase
        .from("verifications")
        .select("id")
        .eq("id", verification_id)
        .eq("is_active", true)
        .maybeSingle(),
    );

    if (verificationError) {
      log({ function: FN, level: "error", message: "Failed to check verification", metadata: { detail: verificationError } });
      return errorResponse("Failed to check verification", 500);
    }
    if (!verification) {
      return errorResponse("Verification not found or inactive", 404);
    }

    // Upsert user_verifications (user_id + verification_id unique constraint)
    const { error } = await withSpan(
      "db.upsert.user_verifications", "db.upsert",
      () => supabase
        .from("user_verifications")
        .upsert(
          {
            user_id: userId,
            verification_id,
            data,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id,verification_id" },
        ),
    );

    if (error) {
      log({ function: FN, level: "error", message: "Failed to upsert user verification", metadata: { detail: error } });
      return errorResponse("Failed to save verification data", 500);
    }

    logStatsigEvent(userId, "user_verification_updated", undefined, {
      verification_id,
    }).catch(() => {});

    return successResponse({ success: true });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: FN, level: "error", message: `Error in ${FN}: ${message}` });
    return errorResponse(message, 500);
  }
}));
