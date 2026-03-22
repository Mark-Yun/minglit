import { createClient } from "@supabase/supabase-js";
import { errorResponse } from "./response_utils.ts";

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

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    return errorResponse("Unauthorized", 401);
  }

  return data.user.id;
}
