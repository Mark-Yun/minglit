// user-manage-social — Manage social interactions (like, block, report)
// Replaces direct client writes to social_interactions + report_details

import { createClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

const VALID_INTERACTION_TYPES = ["like", "dislike", "subscribe", "bookmark"];
const VALID_TARGET_TYPES = ["party", "partner", "review", "comment"];
const VALID_REPORT_REASONS = [
  "inappropriate_content",
  "spam",
  "fraud",
  "harassment",
  "other",
];

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Missing server configuration", 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const action = body.action as string | undefined;
  if (!action) return errorResponse("Missing action", 400);

  // ─────────────────────────────────────────
  // toggle — like/dislike/subscribe/bookmark
  // ─────────────────────────────────────────
  if (action === "toggle") {
    const targetId = body.target_id as string | undefined;
    const targetType = body.target_type as string | undefined;
    const interactionType = body.interaction_type as string | undefined;

    if (!targetId || !targetType || !interactionType) {
      return errorResponse("Missing target_id, target_type, or interaction_type", 400);
    }
    if (!VALID_TARGET_TYPES.includes(targetType)) {
      return errorResponse(`Invalid target_type: ${targetType}`, 400);
    }
    if (!VALID_INTERACTION_TYPES.includes(interactionType)) {
      return errorResponse(`Invalid interaction_type: ${interactionType}`, 400);
    }

    // Like/dislike mutual exclusivity — remove opposite
    if (interactionType === "like" || interactionType === "dislike") {
      const opposite = interactionType === "like" ? "dislike" : "like";
      await supabase
        .from("social_interactions")
        .delete()
        .eq("user_id", userId)
        .eq("target_id", targetId)
        .eq("interaction_type", opposite);
    }

    // Check if exists
    const { data: existing } = await supabase
      .from("social_interactions")
      .select("user_id")
      .eq("user_id", userId)
      .eq("target_id", targetId)
      .eq("interaction_type", interactionType)
      .maybeSingle();

    if (existing) {
      // Remove
      await supabase
        .from("social_interactions")
        .delete()
        .eq("user_id", userId)
        .eq("target_id", targetId)
        .eq("interaction_type", interactionType);
      return successResponse({ success: true, active: false });
    } else {
      // Add
      const { error } = await supabase.from("social_interactions").insert({
        user_id: userId,
        target_id: targetId,
        target_type: targetType,
        interaction_type: interactionType,
      });
      if (error) return errorResponse(error.message, 500);
      return successResponse({ success: true, active: true });
    }
  }

  // ─────────────────────────────────────────
  // block
  // ─────────────────────────────────────────
  if (action === "block") {
    const targetId = body.target_id as string | undefined;
    if (!targetId) return errorResponse("Missing target_id", 400);
    if (targetId === userId) return errorResponse("Cannot block yourself", 400);

    const { error } = await supabase.from("social_interactions").upsert({
      user_id: userId,
      target_id: targetId,
      target_type: "partner",
      interaction_type: "block",
    });
    if (error) return errorResponse(error.message, 500);
    return successResponse({ success: true });
  }

  // ─────────────────────────────────────────
  // unblock
  // ─────────────────────────────────────────
  if (action === "unblock") {
    const targetId = body.target_id as string | undefined;
    if (!targetId) return errorResponse("Missing target_id", 400);

    await supabase
      .from("social_interactions")
      .delete()
      .eq("user_id", userId)
      .eq("target_id", targetId)
      .eq("interaction_type", "block");
    return successResponse({ success: true });
  }

  // ─────────────────────────────────────────
  // report — block + report interaction + report_details (atomic)
  // ─────────────────────────────────────────
  if (action === "report") {
    const targetId = body.target_id as string | undefined;
    const reason = body.reason as string | undefined;
    const description = body.description as string | undefined;

    if (!targetId) return errorResponse("Missing target_id", 400);
    if (!reason) return errorResponse("Missing reason", 400);
    if (!VALID_REPORT_REASONS.includes(reason)) {
      return errorResponse(`Invalid reason: ${reason}`, 400);
    }
    if (targetId === userId) return errorResponse("Cannot report yourself", 400);

    // 1. Block
    await supabase.from("social_interactions").upsert({
      user_id: userId,
      target_id: targetId,
      target_type: "partner",
      interaction_type: "block",
    });

    // 2. Report interaction
    await supabase.from("social_interactions").upsert({
      user_id: userId,
      target_id: targetId,
      target_type: "partner",
      interaction_type: "report",
    });

    // 3. Report details
    const { error } = await supabase.from("report_details").insert({
      user_id: userId,
      target_id: targetId,
      target_type: "partner",
      reason,
      description: description ?? null,
    });
    if (error) return errorResponse(error.message, 500);

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
});
