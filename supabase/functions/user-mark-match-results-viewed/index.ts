import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type RequestBody = {
  application_id: string;
};

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  if (ctx.auth.type !== "user") {
    return errorResponse("Unauthorized", 401);
  }

  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const { application_id } = body as Partial<RequestBody>;
  if (typeof application_id !== "string" || application_id.length === 0) {
    return errorResponse("Missing application_id", 400);
  }
  if (!UUID_RE.test(application_id)) {
    return errorResponse("Invalid application_id", 400);
  }

  const { data: application, error: fetchError } = await ctx.supabase
    .from("event_applications")
    .select("id, user_id, match_results_viewed_at")
    .eq("id", application_id)
    .maybeSingle();

  if (fetchError) {
    return errorResponse("Failed to load application", 500);
  }
  if (!application) {
    return errorResponse("Application not found", 404);
  }
  if (application.user_id !== ctx.auth.userId) {
    return errorResponse("Forbidden", 403);
  }

  if (application.match_results_viewed_at) {
    return successResponse({ success: true, already_viewed: true });
  }

  // Fix #2124: move the write path to an EF/service-role update so clients remain read-only under RLS.
  const { error: updateError } = await ctx.supabase
    .from("event_applications")
    .update({
      match_results_viewed_at: new Date().toISOString(),
    })
    .eq("id", application_id)
    .eq("user_id", ctx.auth.userId)
    .is("match_results_viewed_at", null);

  if (updateError) {
    return errorResponse("Failed to mark match results viewed", 500);
  }

  return successResponse({ success: true, already_viewed: false });
};

minglitEdgeFunction(handler);
