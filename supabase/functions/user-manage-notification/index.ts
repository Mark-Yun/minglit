import { createClient } from "@supabase/supabase-js";
import { corsResponse, errorResponse, successResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const { action, notification_id } = body as {
    action?: string;
    notification_id?: string;
  };

  if (!action) {
    return errorResponse("Missing required parameter: action", 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  if (action === "mark_read") {
    if (!notification_id) {
      return errorResponse("Missing required parameter: notification_id", 400);
    }

    const { data, error } = await supabase
      .from("user_notifications")
      .update({ is_read: true })
      .eq("id", notification_id)
      .eq("user_id", userId)
      .select("id")
      .maybeSingle();

    if (error) {
      return errorResponse(error.message, 500);
    }
    if (!data) {
      return errorResponse("Notification not found", 404);
    }

    return successResponse({ success: true });
  }

  if (action === "mark_all_read") {
    const { data, error } = await supabase
      .from("user_notifications")
      .update({ is_read: true })
      .eq("user_id", userId)
      .eq("is_read", false)
      .select("id");

    if (error) {
      return errorResponse(error.message, 500);
    }

    return successResponse({ success: true, count: (data ?? []).length });
  }

  if (action === "delete") {
    if (!notification_id) {
      return errorResponse("Missing required parameter: notification_id", 400);
    }

    const { data, error } = await supabase
      .from("user_notifications")
      .delete()
      .eq("id", notification_id)
      .eq("user_id", userId)
      .select("id")
      .maybeSingle();

    if (error) {
      return errorResponse(error.message, 500);
    }
    if (!data) {
      return errorResponse("Notification not found", 404);
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
});
