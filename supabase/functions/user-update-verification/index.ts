// Fix #2185 (Batch 8): migrate to minglitEdgeFunction wrapper — auth via manifest
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-update-verification";

initStatsig();

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  const { supabase } = ctx;
  if (ctx.auth.type !== "user") return errorResponse("Unexpected auth type", 500);
  const userId = ctx.auth.userId;

  try {
    const body = await parseJsonBody(req);
    if (body instanceof Response) return body;

    const { verification_id, data } = body as {
      verification_id?: string;
      data?: Record<string, unknown>;
    };

    if (!verification_id) {
      return errorResponse("Missing required field: verification_id", 400);
    }
    if (!data || typeof data !== "object") {
      return errorResponse("Missing required field: data", 400);
    }

    // Verify that the verification definition exists
    const { data: verification, error: verificationError } = await withSpan(
      "db.select.verifications",
      "db.select",
      () =>
        supabase
          .from("verifications")
          .select("id")
          .eq("id", verification_id)
          .eq("is_active", true)
          .maybeSingle(),
    );

    if (verificationError) {
      log({
        function: FN,
        level: "error",
        message: "Failed to check verification",
        metadata: { detail: verificationError },
      });
      return errorResponse("Failed to check verification", 500);
    }
    if (!verification) {
      return errorResponse("Verification not found or inactive", 404);
    }

    // Upsert user_verifications (user_id + verification_id unique constraint)
    const { error } = await withSpan(
      "db.upsert.user_verifications",
      "db.upsert",
      () =>
        supabase
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
      log({
        function: FN,
        level: "error",
        message: "Failed to upsert user verification",
        metadata: { detail: error },
      });
      return errorResponse("Failed to save verification data", 500);
    }

    logStatsigEvent(userId, "user_verification_updated", undefined, {
      verification_id,
    }).catch(() => {});

    return successResponse({ success: true });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: `Error in ${FN}: ${message}`,
    });
    return errorResponse(message, 500);
  }
}

minglitEdgeFunction(handler);
