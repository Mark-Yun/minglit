// recurrence-rules — Manage recurring event rules for parties
// Issue #1034: 반복 이벤트 규칙 CRUD + 자동 이벤트 생성
// Fix #2185 (Batch 7): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)

import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import {
  errorResponse,
} from "../_shared/response_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import { handleCreate } from "./_handlers/create.ts";
import { handleUpdate } from "./_handlers/update.ts";
import { handlePause } from "./_handlers/pause.ts";
import { handleResume } from "./_handlers/resume.ts";
import { handleCancel } from "./_handlers/cancel.ts";

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

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  if (ctx.auth.type !== "user") return errorResponse("Unexpected auth type", 500);
  const userId = ctx.auth.userId;

  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;
  if (!action) return errorResponse("Missing action", 400);

  const actionHandler = DISPATCH[action];
  if (!actionHandler) return errorResponse(`Unknown action: ${action}`, 400);
  return actionHandler(body, supabase, userId);
};

minglitEdgeFunction(handler);
