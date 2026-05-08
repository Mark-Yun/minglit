// partner-manage-verification — Manage verification definitions (create, update)
// Issue #308: RLS write strategy 전환
// Fix #2185 (Batch 7): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)

import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseAction } from "../_shared/request_utils.ts";

const VALID_CATEGORIES = [
  "career",
  "asset",
  "marriage",
  "academic",
  "vehicle",
  "etc",
];

// Fields allowed in create action
const CREATE_FIELDS = [
  "category",
  "internal_name",
  "display_name",
  "description",
  "icon_key",
  "form_schema",
] as const;

// Fields allowed in update action (partial update)
const UPDATE_FIELDS = [
  "category",
  "internal_name",
  "display_name",
  "description",
  "icon_key",
  "form_schema",
  "is_active",
] as const;

export const handler = async (req: Request, ctx: EFContext): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  // 1. Environment check (handled by createServiceClient)

  // 2. Auth
  const { supabase } = ctx;
  const userId = (ctx.auth as { type: "user"; userId: string }).userId;

  // 3. Parse body
  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;
  if (!action) return errorResponse("Missing action", 400);

  // ─── create ───
  if (action === "create") {
    const partnerId = body.partner_id;
    if (typeof partnerId !== "string" || !partnerId) {
      return errorResponse("Missing partner_id", 400);
    }

    // Validate required fields
    const category = body.category;
    if (typeof category !== "string" || !VALID_CATEGORIES.includes(category)) {
      return errorResponse("Missing or invalid category", 400);
    }

    const internalName = body.internal_name;
    if (typeof internalName !== "string" || !internalName) {
      return errorResponse("Missing internal_name", 400);
    }

    const displayName = body.display_name;
    if (typeof displayName !== "string" || !displayName) {
      return errorResponse("Missing display_name", 400);
    }

    // Check partner permission
    const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["PARTY_MANAGE"]);
    if (permCheck) return permCheck;

    // Build insert record — only allow whitelisted fields
    const record: Record<string, unknown> = { partner_id: partnerId };
    for (const field of CREATE_FIELDS) {
      if (body[field] !== undefined) {
        record[field] = body[field];
      }
    }

    const { data, error: insertError } = await supabase
      .from("verifications")
      .insert(record)
      .select("id")
      .single();

    if (insertError) {
      return errorResponse(
        `Failed to create verification: ${insertError.message}`,
        500,
      );
    }

    return successResponse({ success: true, id: data.id });
  }

  // ─── update ───
  if (action === "update") {
    const verificationId = body.verification_id;
    if (typeof verificationId !== "string" || !verificationId) {
      return errorResponse("Missing verification_id", 400);
    }

    // Validate category if provided
    if (body.category !== undefined) {
      if (
        typeof body.category !== "string" ||
        !VALID_CATEGORIES.includes(body.category)
      ) {
        return errorResponse("Invalid category", 400);
      }
    }

    // Fetch verification to get partner_id
    const { data: verification, error: fetchError } = await supabase
      .from("verifications")
      .select("id, partner_id")
      .eq("id", verificationId)
      .maybeSingle();

    if (fetchError) {
      return errorResponse("Failed to load verification", 500);
    }
    if (!verification) {
      return errorResponse("Verification not found", 404);
    }

    // Check partner permission
    const permCheck = await requirePartnerPermission(supabase, verification.partner_id, userId, ["PARTY_MANAGE"]);
    if (permCheck) return permCheck;

    // Build update record — only allow whitelisted fields, ignore partner_id
    const updates: Record<string, unknown> = {};
    for (const field of UPDATE_FIELDS) {
      if (body[field] !== undefined) {
        updates[field] = body[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return errorResponse("No fields to update", 400);
    }

    const { error: updateError } = await supabase
      .from("verifications")
      .update(updates)
      .eq("id", verificationId);

    if (updateError) {
      return errorResponse(
        `Failed to update verification: ${updateError.message}`,
        500,
      );
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
};

minglitEdgeFunction(handler);
