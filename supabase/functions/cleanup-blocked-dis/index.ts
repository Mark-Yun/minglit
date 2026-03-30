import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { initSentry, log, withHandler, withSpan } from "../_shared/logger.ts";

const FN = "cleanup-blocked-dis";

await initSentry();

function requireServiceRole(req: Request): Response | null {
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const authHeader = req.headers.get("Authorization") ?? "";

  if (!serviceRoleKey) {
    return errorResponse("SUPABASE_SERVICE_ROLE_KEY not configured", 500);
  }
  if (authHeader !== `Bearer ${serviceRoleKey}`) {
    return errorResponse("Unauthorized", 401);
  }

  return null;
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }
  if (req.method !== "POST") {
    return errorResponse("Method Not Allowed", 405);
  }

  const authError = requireServiceRole(req);
  if (authError) {
    return authError;
  }

  const supabase = createServiceClient();
  const nowIso = new Date().toISOString();

  try {
    const { data, error } = await withSpan(
      "db.delete.expired_blocked_dis",
      "db.delete",
      () =>
        supabase
          .from("blocked_dis")
          .delete()
          .lt("blocked_until", nowIso)
          .select("di_hash"),
    );

    if (error) {
      throw new Error(`Failed to cleanup blocked_dis: ${error.message}`);
    }

    return successResponse({
      success: true,
      deleted_count: data?.length ?? 0,
      executed_at: nowIso,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log({
      function: FN,
      level: "error",
      message: "Unhandled error in cleanup-blocked-dis",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
}));
