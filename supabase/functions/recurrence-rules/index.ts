// recurrence-rules — Manage recurring event rules for parties
// Issue #1034: 반복 이벤트 규칙 CRUD + 자동 이벤트 생성

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

const VALID_PATTERNS = ["weekly", "biweekly", "monthly"] as const;
type Pattern = typeof VALID_PATTERNS[number];

interface RecurrenceRule {
  id: string;
  party_id: string;
  pattern: Pattern;
  days_of_week: number[];
  month_day: number | null;
  start_time: string;
  end_time: string;
  end_date: string | null;
  status: string;
  last_generated_date: string | null;
  created_at: string;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  try {
    return await handleRequest(req);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(message, 500);
  }
});

async function handleRequest(req: Request): Promise<Response> {
  // Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // Parse body
  let body: Record<string, unknown>;
  try {
    const parsed = await req.json();
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      return errorResponse("Request body must be a JSON object", 400);
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const action = body.action as string | undefined;
  if (typeof action !== "string" || !action) return errorResponse("Missing action", 400);

  const supabase = createServiceClient();

  if (action === "create") return handleCreate(supabase, body, userId);
  if (action === "update") return handleUpdate(supabase, body, userId);
  if (action === "pause") return handlePause(supabase, body, userId);
  if (action === "resume") return handleResume(supabase, body, userId);
  if (action === "cancel") return handleCancel(supabase, body, userId);

  return errorResponse(`Unknown action: ${action}`, 400);
}

// ─── Action Handlers ───

async function handleCreate(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const partyId = body.party_id;
  if (typeof partyId !== "string" || !partyId) {
    return errorResponse("Missing party_id", 400);
  }

  const pattern = body.pattern;
  if (typeof pattern !== "string" || !VALID_PATTERNS.includes(pattern as Pattern)) {
    return errorResponse(`Invalid pattern. Must be one of: ${VALID_PATTERNS.join(", ")}`, 400);
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
  if (monthDay !== null && (typeof monthDay !== "number" || monthDay < 1 || monthDay > 31)) {
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
  if ((pattern === "weekly" || pattern === "biweekly") && daysOfWeek.length === 0) {
    return errorResponse("days_of_week is required for weekly/biweekly pattern", 400);
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
  const permCheck = await checkPartnerPermission(supabase, party.partner_id, userId);
  if (permCheck instanceof Response) return permCheck;

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
    .select("id, party_id, pattern, days_of_week, month_day, start_time, end_time, end_date, status, last_generated_date, created_at")
    .single();

  if (insertError) {
    return errorResponse(`Failed to create recurrence rule: ${insertError.message}`, 500);
  }

  // Generate events for today → today+30 days
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  const toDate = new Date(today);
  toDate.setUTCDate(toDate.getUTCDate() + 30);

  const eventsCreated = await generateEvents(supabase, rule as RecurrenceRule, today, toDate);

  return successResponse({ success: true, rule_id: rule.id, events_created: eventsCreated });
}

async function handleUpdate(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
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

  const partnerId = (rule.parties as Record<string, unknown>).partner_id as string;
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  // Build update object from optional fields
  const updates: Record<string, unknown> = {};

  if (body.pattern !== undefined) {
    if (!VALID_PATTERNS.includes(body.pattern as Pattern)) {
      return errorResponse(`Invalid pattern. Must be one of: ${VALID_PATTERNS.join(", ")}`, 400);
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
    if (typeof body.start_time !== "string" || !/^\d{2}:\d{2}$/.test(body.start_time)) {
      return errorResponse("start_time must be in HH:MM format", 400);
    }
    updates.start_time = body.start_time;
  }

  if (body.end_time !== undefined) {
    if (typeof body.end_time !== "string" || !/^\d{2}:\d{2}$/.test(body.end_time)) {
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
    return errorResponse(`Failed to update recurrence rule: ${updateError.message}`, 500);
  }

  return successResponse({ success: true });
}

async function handlePause(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const ruleId = body.rule_id;
  if (typeof ruleId !== "string" || !ruleId) {
    return errorResponse("Missing rule_id", 400);
  }

  const { data: rule, error: fetchError } = await supabase
    .from("recurrence_rules")
    .select("id, status, parties!inner(partner_id)")
    .eq("id", ruleId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load recurrence rule", 500);
  if (!rule) return errorResponse("Recurrence rule not found", 404);

  if (rule.status !== "active") {
    return errorResponse(`Cannot pause a rule with status: ${rule.status}`, 400);
  }

  const partnerId = (rule.parties as Record<string, unknown>).partner_id as string;
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  const { error: updateError } = await supabase
    .from("recurrence_rules")
    .update({ status: "paused" })
    .eq("id", ruleId);

  if (updateError) {
    return errorResponse(`Failed to pause rule: ${updateError.message}`, 500);
  }

  return successResponse({ success: true });
}

async function handleResume(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const ruleId = body.rule_id;
  if (typeof ruleId !== "string" || !ruleId) {
    return errorResponse("Missing rule_id", 400);
  }

  const { data: rule, error: fetchError } = await supabase
    .from("recurrence_rules")
    .select("id, party_id, pattern, days_of_week, month_day, start_time, end_time, end_date, status, last_generated_date, created_at, parties!inner(partner_id)")
    .eq("id", ruleId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load recurrence rule", 500);
  if (!rule) return errorResponse("Recurrence rule not found", 404);

  if (rule.status !== "paused") {
    return errorResponse(`Cannot resume a rule with status: ${rule.status}`, 400);
  }

  const partnerId = (rule.parties as Record<string, unknown>).partner_id as string;
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  // Activate first
  const { error: updateError } = await supabase
    .from("recurrence_rules")
    .update({ status: "active" })
    .eq("id", ruleId);

  if (updateError) {
    return errorResponse(`Failed to resume rule: ${updateError.message}`, 500);
  }

  // Generate missing events: from last_generated_date (or today) → today+30
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  let fromDate = today;
  if (rule.last_generated_date) {
    const lastGen = new Date(rule.last_generated_date);
    lastGen.setUTCHours(0, 0, 0, 0);
    // Generate from day after last_generated_date
    const nextDay = new Date(lastGen);
    nextDay.setUTCDate(nextDay.getUTCDate() + 1);
    if (nextDay < today) fromDate = nextDay;
  }

  const toDate = new Date(today);
  toDate.setUTCDate(toDate.getUTCDate() + 30);

  // Build rule object without the joined parties field
  const ruleData: RecurrenceRule = {
    id: rule.id,
    party_id: rule.party_id,
    pattern: rule.pattern,
    days_of_week: rule.days_of_week,
    month_day: rule.month_day,
    start_time: rule.start_time,
    end_time: rule.end_time,
    end_date: rule.end_date,
    status: "active",
    last_generated_date: rule.last_generated_date,
    created_at: rule.created_at,
  };

  const eventsCreated = await generateEvents(supabase, ruleData, fromDate, toDate);

  return successResponse({ success: true, events_created: eventsCreated });
}

async function handleCancel(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const ruleId = body.rule_id;
  if (typeof ruleId !== "string" || !ruleId) {
    return errorResponse("Missing rule_id", 400);
  }

  const { data: rule, error: fetchError } = await supabase
    .from("recurrence_rules")
    .select("id, status, parties!inner(partner_id)")
    .eq("id", ruleId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load recurrence rule", 500);
  if (!rule) return errorResponse("Recurrence rule not found", 404);

  if (rule.status === "cancelled") {
    return errorResponse("Rule is already cancelled", 400);
  }

  const partnerId = (rule.parties as Record<string, unknown>).partner_id as string;
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  const { error: updateError } = await supabase
    .from("recurrence_rules")
    .update({ status: "cancelled" })
    .eq("id", ruleId);

  if (updateError) {
    return errorResponse(`Failed to cancel rule: ${updateError.message}`, 500);
  }

  return successResponse({ success: true });
}

// ─── Event Generation ───

async function generateEvents(
  supabase: SupabaseClient,
  rule: RecurrenceRule,
  fromDate: Date,
  toDate: Date,
): Promise<number> {
  const dates = calculateDates(rule, fromDate, toDate);
  if (dates.length === 0) return 0;

  // Fetch templates for this party
  const { data: entryGroupTemplates, error: egtError } = await supabase
    .from("entry_group_templates")
    .select("id, label, gender, birth_year_min, birth_year_max, required_verification_ids")
    .eq("party_id", rule.party_id);

  if (egtError) throw new Error(`Failed to fetch entry group templates: ${egtError.message}`);

  const { data: ticketTemplates, error: ttError } = await supabase
    .from("ticket_templates")
    .select("id, name, description, price, target_entry_group_ids, required_verification_ids")
    .eq("party_id", rule.party_id);

  if (ttError) throw new Error(`Failed to fetch ticket templates: ${ttError.message}`);

  let eventsInserted = 0;

  for (const date of dates) {
    const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD

    const eventStartTime = `${dateStr}T${rule.start_time}:00Z`;
    const eventEndTime = `${dateStr}T${rule.end_time}:00Z`;

    // Insert event with ON CONFLICT DO NOTHING handled by DB unique index
    const { data: newEvent, error: eventError } = await supabase
      .from("events")
      .insert({
        party_id: rule.party_id,
        recurrence_rule_id: rule.id,
        start_time: eventStartTime,
        end_time: eventEndTime,
        status: "scheduled",
      })
      .select("id")
      .maybeSingle();

    if (eventError) {
      // Unique constraint violation — skip (duplicate)
      if (eventError.code === "23505") continue;
      throw new Error(`Failed to insert event for ${dateStr}: ${eventError.message}`);
    }

    if (!newEvent) {
      // Conflict — event already exists
      continue;
    }

    const eventId = newEvent.id as string;
    eventsInserted++;

    // Copy entry_group_templates → entry_groups
    const templateToGroupMap = new Map<string, string>();

    if (entryGroupTemplates && entryGroupTemplates.length > 0) {
      const entryGroups = entryGroupTemplates.map((t: Record<string, unknown>) => ({
        event_id: eventId,
        label: t.label ?? null,
        gender: t.gender ?? null,
        birth_year_min: t.birth_year_min ?? null,
        birth_year_max: t.birth_year_max ?? null,
        required_verification_ids: t.required_verification_ids ?? [],
      }));

      const { data: insertedGroups, error: egError } = await supabase
        .from("entry_groups")
        .insert(entryGroups)
        .select("id");

      if (egError) throw new Error(`Failed to create entry groups: ${egError.message}`);

      if (insertedGroups) {
        for (let i = 0; i < entryGroupTemplates.length; i++) {
          templateToGroupMap.set(
            entryGroupTemplates[i].id as string,
            (insertedGroups[i] as Record<string, unknown>).id as string,
          );
        }
      }
    }

    // Copy ticket_templates → tickets
    if (ticketTemplates && ticketTemplates.length > 0) {
      const tickets = ticketTemplates.map((tpl: Record<string, unknown>) => {
        const originalTargetIds = (tpl.target_entry_group_ids as string[]) ?? [];
        const remappedTargetIds = originalTargetIds
          .map((id: string) => templateToGroupMap.get(id))
          .filter((id): id is string => id !== undefined);

        return {
          event_id: eventId,
          name: tpl.name,
          description: tpl.description ?? null,
          price: tpl.price ?? 0,
          quantity: 0,
          target_entry_group_ids: remappedTargetIds,
          required_verification_ids: tpl.required_verification_ids ?? [],
        };
      });

      const { error: ticketError } = await supabase
        .from("tickets")
        .insert(tickets);

      if (ticketError) throw new Error(`Failed to create tickets: ${ticketError.message}`);
    }
  }

  // Update last_generated_date to the last date we iterated over
  if (dates.length > 0) {
    const lastDate = dates[dates.length - 1];
    const lastDateStr = lastDate.toISOString().slice(0, 10);
    await supabase
      .from("recurrence_rules")
      .update({ last_generated_date: lastDateStr })
      .eq("id", rule.id);
  }

  return eventsInserted;
}

function calculateDates(
  rule: RecurrenceRule,
  fromDate: Date,
  toDate: Date,
): Date[] {
  const dates: Date[] = [];
  const endDate = rule.end_date ? new Date(rule.end_date + "T00:00:00Z") : null;

  // Reference date for biweekly: based on rule creation date
  const createdAt = new Date(rule.created_at);
  createdAt.setUTCHours(0, 0, 0, 0);

  const current = new Date(fromDate);

  while (current <= toDate) {
    // Don't go past rule's end_date
    if (endDate && current > endDate) break;

    const dayOfWeek = current.getUTCDay(); // 0=Sun, 6=Sat
    const dayOfMonth = current.getUTCDate();

    let shouldGenerate = false;

    if (rule.pattern === "weekly") {
      shouldGenerate = rule.days_of_week.includes(dayOfWeek);
    } else if (rule.pattern === "biweekly") {
      if (rule.days_of_week.includes(dayOfWeek)) {
        const diffDays = Math.floor(
          (current.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24),
        );
        // Handle negative diffDays correctly
        const mod14 = ((diffDays % 14) + 14) % 14;
        shouldGenerate = mod14 < 7;
      }
    } else if (rule.pattern === "monthly") {
      shouldGenerate = rule.month_day !== null && dayOfMonth === rule.month_day;
    }

    if (shouldGenerate) {
      dates.push(new Date(current));
    }

    current.setUTCDate(current.getUTCDate() + 1);
  }

  return dates;
}

// ─── Helpers ───

async function checkPartnerPermission(
  supabase: SupabaseClient,
  partnerId: string,
  userId: string,
): Promise<void | Response> {
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("permissions")
    .eq("partner_id", partnerId)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  const permissions = (perm?.permissions as string[] | null) ?? [];
  const hasPermission = permissions.includes("PARTY_MANAGE");
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
