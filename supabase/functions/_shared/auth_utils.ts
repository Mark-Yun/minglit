// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "./supabase_client.ts";
import { errorResponse } from "./response_utils.ts";

/**
 * Verify that the request bears the service_role key.
 *
 * Compares the Bearer token in the Authorization header against
 * `SUPABASE_SERVICE_ROLE_KEY`. Returns `true` on success,
 * or a 401 Response on failure.
 *
 * Usage:
 * ```ts
 * const auth = requireServiceRole(req);
 * if (auth instanceof Response) return auth; // 401
 * ```
 */
export function requireServiceRole(req: Request): true | Response {
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!authHeader || authHeader !== `Bearer ${serviceRoleKey}`) {
    return errorResponse("Unauthorized", 401);
  }
  return true;
}

/**
 * Extract Bearer token from Authorization header and verify it
 * against Supabase Auth using `auth.getUser()`.
 *
 * Returns the authenticated user ID, or a 401 Response on failure.
 *
 * Usage:
 * ```ts
 * const auth = await requireAuth(req);
 * if (auth instanceof Response) return auth; // 401
 * const userId = auth;
 * ```
 */
export async function requireAuth(
  req: Request,
): Promise<string | Response> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return errorResponse("Missing or invalid Authorization header", 401);
  }

  const token = authHeader.replace("Bearer ", "");

  const supabase = createServiceClient();

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    return errorResponse("Unauthorized", 401);
  }

  return data.user.id;
}
