import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { VALID_PATTERNS, type Pattern } from "../_lib/types.ts";

export async function handleUpdate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const ruleId = body.rule_id;
  if (typeof ruleId !== "string" || !ruleId) {
    return errorResponse("Missing rule_id", 400);
  }

  // Fetch rule to get party info
  const { data: rule, error: fetchError } = await supabase
    .from("recurrence_rules")
    .select("id, party_id, status, parties!inner(partner_id)")
    .eq("id", ruleId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load recurrence rule", 500);
  if (!rule) return errorResponse("Recurrence rule not found", 404);

  if (rule.status === "cancelled") {
    return errorResponse("Cannot update a cancelled rule", 400);
  }

  const partnerId = (rule.parties as unknown as Record<string, unknown>).partner_id as string;
  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["PARTY_MANAGE"]);
  if (permCheck) return permCheck;

  // Build update object from optional fields
  const updates: Record<string, unknown> = {};

  if (body.pattern !== undefined) {
    if (!VALID_PATTERNS.includes(body.pattern as Pattern)) {
      return errorResponse(
        `Invalid pattern. Must be one of: ${VALID_PATTERNS.join(", ")}`,
        400,
      );
    }
    updates.pattern = body.pattern;
  }

  if (body.days_of_week !== undefined) {
    if (!Array.isArray(body.days_of_week)) {
      return errorResponse("days_of_week must be an array", 400);
    }
    updates.days_of_week = body.days_of_week;
  }

  if (body.month_day !== undefined) {
    updates.month_day = body.month_day;
  }

  if (body.start_time !== undefined) {
    if (
      typeof body.start_time !== "string" ||
      !/^\d{2}:\d{2}$/.test(body.start_time)
    ) {
      return errorResponse("start_time must be in HH:MM format", 400);
    }
    updates.start_time = body.start_time;
  }

  if (body.end_time !== undefined) {
    if (
      typeof body.end_time !== "string" || !/^\d{2}:\d{2}$/.test(body.end_time)
    ) {
      return errorResponse("end_time must be in HH:MM format", 400);
    }
    updates.end_time = body.end_time;
  }

  if (body.end_date !== undefined) {
    updates.end_date = body.end_date;
  }

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update", 400);
  }

  // Reset last_generated_date so events are regenerated from today
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  updates.last_generated_date = today.toISOString().slice(0, 10);

  const { error: updateError } = await supabase
    .from("recurrence_rules")
    .update(updates)
    .eq("id", ruleId);

  if (updateError) {
    return errorResponse(
      `Failed to update recurrence rule: ${updateError.message}`,
      500,
    );
  }

  return successResponse({ success: true });
}
