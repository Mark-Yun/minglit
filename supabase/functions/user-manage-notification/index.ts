import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

export const handler = async (req: Request, { auth, supabase }: EFContext): Promise<Response> => {
  const { userId } = auth as { type: "user"; userId: string };

  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;
  const { notification_id } = body as {
    notification_id?: string;
  };
  if (!action) {
    return errorResponse("Missing required parameter: action", 400);
  }

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
};

minglitEdgeFunction(handler);
