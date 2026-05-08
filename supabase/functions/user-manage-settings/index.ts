// user-manage-settings — FCM token registration and user settings management
// Issue #2040: atomic upsert for user_settings + user_consents via RPC

import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { log, withSpan } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-manage-settings";

const ALLOWED_SETTINGS_FIELDS = ["marketing_consent", "service_notification"];
const VALID_DEVICE_TYPES = ["android", "ios", "web"];

initStatsig();

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  // wrapper guarantees type === "user" per auth-manifest callers: ["user"]
  const userId = (ctx.auth as { type: "user"; userId: string }).userId;
  const { supabase } = ctx;

  try {
    const result = await parseAction(req);
    if (result instanceof Response) return result;
    const { action, body } = result;

    switch (action) {
      case "upsert_token": {
        const { token, device_type } = body as {
          token?: string;
          device_type?: string;
        };

        if (!token) {
          return errorResponse("Missing required field: token", 400);
        }
        if (!device_type || !VALID_DEVICE_TYPES.includes(device_type)) {
          return errorResponse(
            `Invalid device_type. Must be one of: ${VALID_DEVICE_TYPES.join(", ")}`,
            400,
          );
        }

        const { error } = await withSpan(
          "db.upsert.fcm_tokens",
          "db.upsert",
          () =>
            supabase
              .from("fcm_tokens")
              .upsert(
                {
                  user_id: userId,
                  token,
                  device_type,
                  last_updated_at: new Date().toISOString(),
                },
                { onConflict: "token" },
              ),
        );

        if (error) {
          log({
            function: FN,
            level: "error",
            message: "Failed to upsert FCM token",
            metadata: { detail: error },
          });
          return errorResponse("Failed to upsert token", 500);
        }

        logStatsigEvent(userId, "fcm_token_upserted", undefined, {
          device_type,
        }).catch(() => {});

        return successResponse({ success: true });
      }

      case "delete_token": {
        const { token } = body as { token?: string };

        if (!token) {
          return errorResponse("Missing required field: token", 400);
        }

        const { error } = await withSpan(
          "db.delete.fcm_tokens",
          "db.delete",
          () =>
            supabase
              .from("fcm_tokens")
              .delete()
              .eq("token", token)
              .eq("user_id", userId),
        );

        if (error) {
          log({
            function: FN,
            level: "error",
            message: "Failed to delete FCM token",
            metadata: { detail: error },
          });
          return errorResponse("Failed to delete token", 500);
        }

        logStatsigEvent(userId, "fcm_token_deleted").catch(() => {});

        return successResponse({ success: true });
      }

      case "update_settings": {
        const { settings } = body as {
          settings?: Record<string, unknown>;
        };

        if (!settings || typeof settings !== "object") {
          return errorResponse("Missing required field: settings", 400);
        }

        // Whitelist allowed fields
        const sanitized: Record<string, unknown> = {};
        for (const key of ALLOWED_SETTINGS_FIELDS) {
          if (key in settings) {
            if (typeof settings[key] !== "boolean") {
              return errorResponse(`Field '${key}' must be a boolean`, 400);
            }
            sanitized[key] = settings[key];
          }
        }

        if (Object.keys(sanitized).length === 0) {
          return errorResponse(
            `No valid settings fields. Allowed: ${ALLOWED_SETTINGS_FIELDS.join(", ")}`,
            400,
          );
        }

        // Fix #2040: user_settings + user_consents를 원자적 RPC로 동시 갱신 (partial write 방지)
        const { data, error } = await withSpan(
          "db.rpc.upsert_user_settings_with_consent",
          "db.rpc",
          () =>
            supabase.rpc("upsert_user_settings_with_consent", {
              p_user_id: userId,
              p_marketing_consent: "marketing_consent" in sanitized
                ? sanitized["marketing_consent"] as boolean
                : null,
              p_service_notification: "service_notification" in sanitized
                ? sanitized["service_notification"] as boolean
                : null,
            }),
        );

        if (error) {
          log({
            function: FN,
            level: "error",
            message: "Failed to update settings",
            metadata: { userId, detail: error },
          });
          return errorResponse("Failed to update settings", 500);
        }

        logStatsigEvent(
          userId,
          "settings_updated",
          undefined,
          Object.fromEntries(
            Object.entries(sanitized).map(([k, v]) => [k, String(v)]),
          ),
        ).catch(() => {});

        return successResponse({ success: true, settings: data });
      }

      default:
        return errorResponse(`Unknown action: ${action}`, 400);
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({
      function: FN,
      level: "error",
      message: `Error in ${FN}: ${message}`,
    });
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);
