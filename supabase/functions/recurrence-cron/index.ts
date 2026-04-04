import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireServiceRole } from "../_shared/auth_utils.ts";
import { initSentry, log, withHandler } from "../_shared/logger.ts";

await initSentry();

const FN = "recurrence-cron";
const LOOKAHEAD_DAYS = 30;

interface RecurrenceRule {
  id: string;
  party_id: string;
  pattern: "weekly" | "biweekly" | "monthly";
  days_of_week: number[];
  month_day: number | null;
  start_time: string;
  end_time: string;
  end_date: string | null;
  status: string;
  last_generated_date: string | null;
  created_at: string;
}

interface EntryGroupTemplate {
  id: string;
  party_id: string;
  label: string;
  gender: string | null;
  birth_year_min: number | null;
  birth_year_max: number | null;
  required_verification_ids: string[];
}

interface TicketTemplate {
  id: string;
  party_id: string;
  name: string;
  price: number;
  quantity: number;
  target_entry_group_ids: string[];
}

/** Add days to a Date, returning a new Date. */
function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

/** Format a Date as YYYY-MM-DD string (UTC). */
function toDateStr(date: Date): string {
  return date.toISOString().split("T")[0];
}

/** Parse a YYYY-MM-DD string into a UTC midnight Date. */
function parseDate(str: string): Date {
  return new Date(`${str}T00:00:00Z`);
}

/**
 * Determine whether a given target date should produce an event for the rule.
 */
function shouldGenerate(rule: RecurrenceRule, targetDate: Date): boolean {
  if (rule.pattern === "weekly") {
    return rule.days_of_week.includes(targetDate.getUTCDay());
  }

  if (rule.pattern === "biweekly") {
    if (!rule.days_of_week.includes(targetDate.getUTCDay())) return false;
    const createdDate = parseDate(rule.created_at.split("T")[0]);
    const diffMs = targetDate.getTime() - createdDate.getTime();
    const diffDays = Math.round(diffMs / (24 * 60 * 60 * 1000));
    return ((diffDays % 14) + 14) % 14 < 7;
  }

  if (rule.pattern === "monthly") {
    return rule.month_day !== null && targetDate.getUTCDate() === rule.month_day;
  }

  return false;
}

interface RuleProcessResult {
  rule_id: string;
  events_created: number;
  skipped_duplicates: number;
  errors: number;
}

async function processRule(
  supabase: ReturnType<typeof createServiceClient>,
  rule: RecurrenceRule,
  today: Date,
  lookaheadEnd: Date,
): Promise<RuleProcessResult> {
  // Compute start date for generation window
  let startDate: Date;
  if (rule.last_generated_date) {
    startDate = addDays(parseDate(rule.last_generated_date), 1);
    if (startDate < today) startDate = today;
  } else {
    startDate = today;
  }

  // Respect rule's end_date
  let endDate = lookaheadEnd;
  if (rule.end_date) {
    const ruleEndDate = parseDate(rule.end_date);
    if (ruleEndDate < endDate) endDate = ruleEndDate;
  }

  // If the generation window is empty (end_date already past), skip
  if (endDate < startDate) {
    return { rule_id: rule.id, events_created: 0, skipped_duplicates: 0, errors: 0 };
  }

  // Load templates for this party
  const [entryGroupTemplatesResult, ticketTemplatesResult] = await Promise.all([
    supabase
      .from("entry_group_templates")
      .select("id, party_id, label, gender, birth_year_min, birth_year_max, required_verification_ids")
      .eq("party_id", rule.party_id),
    supabase
      .from("ticket_templates")
      .select("id, party_id, name, price, quantity, target_entry_group_ids")
      .eq("party_id", rule.party_id),
  ]);

  const entryGroupTemplates: EntryGroupTemplate[] =
    (entryGroupTemplatesResult.data ?? []) as EntryGroupTemplate[];
  const ticketTemplates: TicketTemplate[] =
    (ticketTemplatesResult.data ?? []) as TicketTemplate[];

  let eventsCreated = 0;
  let skippedDuplicates = 0;
  let errors = 0;
  let lastGeneratedDate: Date | null = null;

  // Iterate over each candidate date in [startDate, endDate]
  const cursor = new Date(startDate);
  while (cursor <= endDate) {
    const targetDate = new Date(cursor);
    cursor.setUTCDate(cursor.getUTCDate() + 1);

    if (!shouldGenerate(rule, targetDate)) continue;

    const dateStr = toDateStr(targetDate);
    const startTimestamp = `${dateStr}T${rule.start_time}Z`;
    const endTimestamp = `${dateStr}T${rule.end_time}Z`;

    // Insert the event (ON CONFLICT DO NOTHING via maybeSingle + error code check)
    const { data: event, error: eventError } = await supabase
      .from("events")
      .insert({
        party_id: rule.party_id,
        recurrence_rule_id: rule.id,
        start_time: startTimestamp,
        end_time: endTimestamp,
        status: "scheduled",
      })
      .select("id")
      .maybeSingle();

    if (eventError) {
      if (eventError.code === "23505") {
        // Duplicate — already exists; count as skipped
        skippedDuplicates += 1;
        lastGeneratedDate = targetDate;
        continue;
      }
      log({
        function: FN,
        level: "error",
        message: "Failed to insert event",
        metadata: { rule_id: rule.id, date: dateStr, detail: eventError.message },
      });
      errors += 1;
      continue;
    }

    if (!event) {
      // No row returned without error means conflict was ignored silently
      skippedDuplicates += 1;
      lastGeneratedDate = targetDate;
      continue;
    }

    const eventId = event.id as string;

    // Copy entry_group_templates → entry_groups, tracking old→new id mapping
    const entryGroupIdMap = new Map<string, string>();

    if (entryGroupTemplates.length > 0) {
      const entryGroupRows = entryGroupTemplates.map((tpl) => ({
        event_id: eventId,
        label: tpl.label,
        gender: tpl.gender,
        birth_year_min: tpl.birth_year_min,
        birth_year_max: tpl.birth_year_max,
        required_verification_ids: tpl.required_verification_ids,
      }));

      const { data: insertedGroups, error: groupError } = await supabase
        .from("entry_groups")
        .insert(entryGroupRows)
        .select("id, label");

      if (groupError) {
        log({
          function: FN,
          level: "error",
          message: "Failed to insert entry_groups",
          metadata: { event_id: eventId, rule_id: rule.id, detail: groupError.message },
        });
        errors += 1;
        continue;
      }

      // Build mapping from template id → new entry_group id by matching label
      const insertedGroupsByLabel = new Map(
        (insertedGroups ?? []).map((g: { id: string; label: string }) => [g.label, g.id]),
      );
      for (const tpl of entryGroupTemplates) {
        const newId = insertedGroupsByLabel.get(tpl.label);
        if (newId) {
          entryGroupIdMap.set(tpl.id, newId);
        }
      }
    }

    // Copy ticket_templates → tickets (remap target_entry_group_ids)
    if (ticketTemplates.length > 0) {
      const ticketRows = ticketTemplates.map((tpl) => ({
        event_id: eventId,
        name: tpl.name,
        price: tpl.price,
        quantity: tpl.quantity,
        target_entry_group_ids: tpl.target_entry_group_ids.map(
          (oldId) => entryGroupIdMap.get(oldId) ?? oldId,
        ),
      }));

      const { error: ticketError } = await supabase
        .from("tickets")
        .insert(ticketRows);

      if (ticketError) {
        log({
          function: FN,
          level: "error",
          message: "Failed to insert tickets",
          metadata: { event_id: eventId, rule_id: rule.id, detail: ticketError.message },
        });
        errors += 1;
        continue;
      }
    }

    eventsCreated += 1;
    lastGeneratedDate = targetDate;
  }

  // Update last_generated_date to the furthest date we processed (endDate or last generated)
  const finalDate = lastGeneratedDate ?? (endDate < today ? endDate : today);
  await supabase
    .from("recurrence_rules")
    .update({ last_generated_date: toDateStr(finalDate) })
    .eq("id", rule.id);

  return {
    rule_id: rule.id,
    events_created: eventsCreated,
    skipped_duplicates: skippedDuplicates,
    errors,
  };
}

async function processAllActiveRules(
  supabase: ReturnType<typeof createServiceClient>,
): Promise<RuleProcessResult[]> {
  const { data: rules, error } = await supabase
    .from("recurrence_rules")
    .select(
      "id, party_id, pattern, days_of_week, month_day, start_time, end_time, end_date, status, last_generated_date, created_at",
    )
    .eq("status", "active");

  if (error) {
    throw new Error(`Failed to load recurrence rules: ${error.message}`);
  }

  const today = new Date();
  // Normalize to UTC midnight
  const todayStr = toDateStr(today);
  const todayUtc = parseDate(todayStr);
  const lookaheadEnd = addDays(todayUtc, LOOKAHEAD_DAYS);

  const results: RuleProcessResult[] = [];

  for (const rule of (rules ?? []) as RecurrenceRule[]) {
    try {
      const result = await processRule(supabase, rule, todayUtc, lookaheadEnd);
      results.push(result);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      log({
        function: FN,
        level: "error",
        message: "Unhandled error processing recurrence rule",
        metadata: { rule_id: rule.id, detail: message },
      });
      results.push({ rule_id: rule.id, events_created: 0, skipped_duplicates: 0, errors: 1 });
    }
  }

  return results;
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method Not Allowed", 405);

  const authCheck = requireServiceRole(req);
  if (authCheck instanceof Response) return authCheck;

  const supabase = createServiceClient();

  try {
    const results = await processAllActiveRules(supabase);
    const totalEvents = results.reduce((sum, r) => sum + r.events_created, 0);
    const totalSkipped = results.reduce((sum, r) => sum + r.skipped_duplicates, 0);
    const totalErrors = results.reduce((sum, r) => sum + r.errors, 0);

    return successResponse({
      processed: results.length,
      total_events: totalEvents,
      total_skipped: totalSkipped,
      total_errors: totalErrors,
      results,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    log({
      function: FN,
      level: "error",
      message: "Unhandled error in recurrence-cron",
      metadata: { detail: message },
    });
    return errorResponse(message, 500);
  }
}));
