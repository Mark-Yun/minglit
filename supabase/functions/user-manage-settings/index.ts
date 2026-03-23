import { createClient } from "@supabase/supabase-js";
import { successResponse, errorResponse, corsResponse } from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler, withSpan, log } from "../_shared/logger.ts";
import { initStatsig, logStatsigEvent } from "../_shared/statsig_utils.ts";

const FN = "user-manage-settings";

const ALLOWED_SETTINGS_FIELDS = ["marketing_consent", "service_notification"];
const VALID_DEVICE_TYPES = ["android", "ios", "web"];

initSentry();
initStatsig();

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  try {
    // 1. Parse Request
    let reqBody: Record<string, unknown>;
    try {
      reqBody = await req.json();
    } catch {
      return errorResponse("Invalid JSON body", 400);
    }

    const { action } = reqBody as { action?: string };

    if (!action) {
      return errorResponse("Missing required field: action", 400);
    }

    // 2. Init Supabase (service role)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    switch (action) {
      case "upsert_token": {
        const { token, device_type } = reqBody as {
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
          "db.upsert.fcm_tokens", "db.upsert",
          () => supabase
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
          log({ function: FN, level: "error", message: "Failed to upsert FCM token", metadata: { detail: error } });
          return errorResponse("Failed to upsert token", 500);
        }

        logStatsigEvent(userId, "fcm_token_upserted", undefined, {
          device_type,
        }).catch(() => {});

        return successResponse({ success: true });
      }

      case "delete_token": {
        const { token } = reqBody as { token?: string };

        if (!token) {
          return errorResponse("Missing required field: token", 400);
        }

        const { error } = await withSpan(
          "db.delete.fcm_tokens", "db.delete",
          () => supabase
            .from("fcm_tokens")
            .delete()
            .eq("token", token)
            .eq("user_id", userId),
        );

        if (error) {
          log({ function: FN, level: "error", message: "Failed to delete FCM token", metadata: { detail: error } });
          return errorResponse("Failed to delete token", 500);
        }

        logStatsigEvent(userId, "fcm_token_deleted").catch(() => {});

        return successResponse({ success: true });
      }

      case "update_settings": {
        const { settings } = reqBody as {
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

        const { data, error } = await withSpan(
          "db.upsert.user_settings", "db.upsert",
          () => supabase
            .from("user_settings")
            .upsert(
              {
                user_id: userId,
                ...sanitized,
                updated_at: new Date().toISOString(),
              },
              { onConflict: "user_id" },
            )
            .select()
            .single(),
        );

        if (error) {
          log({ function: FN, level: "error", message: "Failed to update settings", metadata: { detail: error } });
          return errorResponse("Failed to update settings", 500);
        }

        logStatsigEvent(userId, "settings_updated", undefined,
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
    log({ function: FN, level: "error", message: `Error in ${FN}: ${message}` });
    return errorResponse(message, 500);
  }
}));
