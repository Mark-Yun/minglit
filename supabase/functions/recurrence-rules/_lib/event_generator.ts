import type { SupabaseClient } from "@supabase/supabase-js";
import type { RecurrenceRule } from "./types.ts";

export async function generateEvents(
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
    .select(
      "id, label, gender, birth_year_min, birth_year_max, required_verification_ids",
    )
    .eq("party_id", rule.party_id);

  if (egtError) {
    throw new Error(
      `Failed to fetch entry group templates: ${egtError.message}`,
    );
  }

  const { data: ticketTemplates, error: ttError } = await supabase
    .from("ticket_templates")
    .select(
      "id, name, description, price, quantity, target_entry_group_ids, required_verification_ids",
    )
    .eq("party_id", rule.party_id);

  if (ttError) {
    throw new Error(`Failed to fetch ticket templates: ${ttError.message}`);
  }

  let eventsInserted = 0;

  for (const date of dates) {
    const dateStr = date.toISOString().slice(0, 10); // YYYY-MM-DD

    const eventStartTime = `${dateStr}T${rule.start_time}Z`;
    const eventEndTime = `${dateStr}T${rule.end_time}Z`;

    // Insert event with ON CONFLICT DO NOTHING handled by DB unique index
    const { data: newEvent, error: eventError } = await supabase
      .from("events")
      .insert({
        party_id: rule.party_id,
        recurrence_rule_id: rule.id,
        start_time: eventStartTime,
        end_time: eventEndTime,
        recurrence_date: dateStr,
        status: "scheduled",
      })
      .select("id")
      .maybeSingle();

    if (eventError) {
      // Unique constraint violation — skip (duplicate)
      if (eventError.code === "23505") continue;
      throw new Error(
        `Failed to insert event for ${dateStr}: ${eventError.message}`,
      );
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
      const entryGroups = entryGroupTemplates.map((
        t: Record<string, unknown>,
      ) => ({
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

      if (egError) {
        throw new Error(`Failed to create entry groups: ${egError.message}`);
      }

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
        const originalTargetIds = (tpl.target_entry_group_ids as string[]) ??
          [];
        const remappedTargetIds = originalTargetIds
          .map((id: string) => templateToGroupMap.get(id))
          .filter((id): id is string => id !== undefined);

        return {
          event_id: eventId,
          name: tpl.name,
          description: tpl.description ?? null,
          price: tpl.price ?? 0,
          quantity: (tpl.quantity as number) ?? 0,
          target_entry_group_ids: remappedTargetIds,
          required_verification_ids: tpl.required_verification_ids ?? [],
        };
      });

      const { error: ticketError } = await supabase
        .from("tickets")
        .insert(tickets);

      if (ticketError) {
        throw new Error(`Failed to create tickets: ${ticketError.message}`);
      }
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

export function calculateDates(
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
