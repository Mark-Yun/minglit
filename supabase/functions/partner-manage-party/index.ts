// partner-manage-party — Party/location/template CRUD for partners
// Issue #316: RLS write strategy 전환

import {
  errorResponse,
} from "../_shared/response_utils.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import { handleCreate } from "./_handlers/create.ts";
import { handleUpdate } from "./_handlers/update.ts";
import { handleUpdateStatus } from "./_handlers/update_status.ts";

type ActionHandler = (
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
) => Promise<Response>;

const DISPATCH: Record<string, ActionHandler> = {
  create: handleCreate,
  update: handleUpdate,
  update_status: handleUpdateStatus,
};

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  // wrapper guarantees type === "user" per auth-manifest callers: ["user"]
  const userId = (ctx.auth as { type: "user"; userId: string }).userId;

  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;

  const actionHandler = DISPATCH[action];
  if (!actionHandler) return errorResponse(`Unknown action: ${action}`, 400);
  return actionHandler(body, supabase, userId);
};

minglitEdgeFunction(handler);
