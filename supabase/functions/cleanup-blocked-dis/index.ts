// Fix #1784: 로컬 requireServiceRole 복사본 제거 → 공식 _shared/auth_utils.ts 사용
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { withSpan } from "../_shared/logger.ts";

export const handler = async (req: Request, { supabase }: EFContext): Promise<Response> => {
  if (req.method !== "POST") {
    return errorResponse("Method Not Allowed", 405);
  }

  const nowIso = new Date().toISOString();

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
};

minglitEdgeFunction(handler);
