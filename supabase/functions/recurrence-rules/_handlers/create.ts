import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { VALID_PATTERNS, type Pattern, type RecurrenceRule } from "../_lib/types.ts";
import { generateEvents } from "../_lib/event_generator.ts";

export async function handleCreate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const partyId = body.party_id;
  if (typeof partyId !== "string" || !partyId) {
    return errorResponse("Missing party_id", 400);
  }

  const pattern = body.pattern;
  if (
    typeof pattern !== "string" || !VALID_PATTERNS.includes(pattern as Pattern)
  ) {
    return errorResponse(
      `Invalid pattern. Must be one of: ${VALID_PATTERNS.join(", ")}`,
      400,
    );
  }

  const daysOfWeek = body.days_of_week;
  if (!Array.isArray(daysOfWeek)) {
    return errorResponse("days_of_week must be an array", 400);
  }
  for (const d of daysOfWeek) {
    if (typeof d !== "number" || d < 0 || d > 6) {
      return errorResponse("days_of_week must contain integers 0-6", 400);
    }
  }

  const monthDay = body.month_day ?? null;
  if (
    monthDay !== null &&
    (typeof monthDay !== "number" || monthDay < 1 || monthDay > 31)
  ) {
    return errorResponse("month_day must be between 1 and 31", 400);
  }

  const startTime = body.start_time;
  if (typeof startTime !== "string" || !/^\d{2}:\d{2}$/.test(startTime)) {
    return errorResponse("start_time must be in HH:MM format", 400);
  }

  const endTime = body.end_time;
  if (typeof endTime !== "string" || !/^\d{2}:\d{2}$/.test(endTime)) {
    return errorResponse("end_time must be in HH:MM format", 400);
  }

  const endDate = body.end_date ?? null;
  if (endDate !== null && typeof endDate !== "string") {
    return errorResponse("end_date must be a date string or null", 400);
  }

  // Validate pattern-specific requirements
  if (pattern === "monthly" && monthDay === null) {
    return errorResponse("month_day is required for monthly pattern", 400);
  }
  if (
    (pattern === "weekly" || pattern === "biweekly") && daysOfWeek.length === 0
  ) {
    return errorResponse(
      "days_of_week is required for weekly/biweekly pattern",
      400,
    );
  }

  // Fetch party to verify it exists and get partner_id
  const { data: party, error: partyError } = await supabase
    .from("parties")
    .select("id, partner_id")
    .eq("id", partyId)
    .maybeSingle();

  if (partyError) return errorResponse("Failed to load party", 500);
  if (!party) return errorResponse("Party not found", 404);

  // Check permission
  const permCheck = await requirePartnerPermission(supabase, party.partner_id, userId, ["PARTY_MANAGE"]);
  if (permCheck) return permCheck;

  // Insert recurrence rule
  const { data: rule, error: insertError } = await supabase
    .from("recurrence_rules")
    .insert({
      party_id: partyId,
      pattern,
      days_of_week: daysOfWeek,
      month_day: monthDay,
      start_time: startTime,
      end_time: endTime,
      end_date: endDate,
    })
    .select(
      "id, party_id, pattern, days_of_week, month_day, start_time, end_time, end_date, status, last_generated_date, created_at",
    )
    .single();

  if (insertError) {
    return errorResponse(
      `Failed to create recurrence rule: ${insertError.message}`,
      500,
    );
  }

  // Generate events for today → today+30 days
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  const toDate = new Date(today);
  toDate.setUTCDate(toDate.getUTCDate() + 30);

  const eventsCreated = await generateEvents(
    supabase,
    rule as RecurrenceRule,
    today,
    toDate,
  );

  return successResponse({
    success: true,
    rule_id: rule.id,
    events_created: eventsCreated,
  });
}
