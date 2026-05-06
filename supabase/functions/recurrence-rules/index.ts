// recurrence-rules — Manage recurring event rules for parties
// Issue #1034: 반복 이벤트 규칙 CRUD + 자동 이벤트 생성

import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import { handleCreate } from "./_handlers/create.ts";
import { handleUpdate } from "./_handlers/update.ts";
import { handlePause } from "./_handlers/pause.ts";
import { handleResume } from "./_handlers/resume.ts";
import { handleCancel } from "./_handlers/cancel.ts";

initSentry();

type ActionHandler = (
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
) => Promise<Response>;

const DISPATCH: Record<string, ActionHandler> = {
  create: handleCreate,
  update: handleUpdate,
  pause: handlePause,
  resume: handleResume,
  cancel: handleCancel,
};

Deno.serve(withHandler(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
    const auth = await requireAuth(req);
    if (auth instanceof Response) return auth;
    const userId = auth;

    const result = await parseAction(req);
    if (result instanceof Response) return result;
    const { action, body } = result;
    if (!action) return errorResponse("Missing action", 400);

    const supabase = createServiceClient();
    const handler = DISPATCH[action];
    if (!handler) return errorResponse(`Unknown action: ${action}`, 400);
    return handler(body, supabase, userId);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(message, 500);
  }
}));
