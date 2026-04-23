import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { initSentry, log, withHandler, withSpan } from "../_shared/logger.ts";
// Fix #1784: 로컬 requireServiceRole 복사본 제거 → 공식 _shared/auth_utils.ts 사용
import { requireServiceRole } from "../_shared/auth_utils.ts";

const FN = "cleanup-blocked-dis";

await initSentry();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }
  if (req.method !== "POST") {
    return errorResponse("Method Not Allowed", 405);
  }

  const auth = requireServiceRole(req);
  if (auth instanceof Response) {
    return auth;
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
