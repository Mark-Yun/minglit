// partner-manage-event — Event/ticket/entry-group CRUD for partners
// Issue #317: RLS write strategy 전환 — 이벤트/티켓 CRUD
// Fix #2185 (Batch 6): migrate to minglitEdgeFunction wrapper — auth via manifest (user caller)

import {
  type EFContext,
  minglitEdgeFunction,
} from "../_shared/edge_function.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import { errorResponse, successResponse } from "../_shared/response_utils.ts";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import { parseAction } from "../_shared/request_utils.ts";
import { isEventEditableByPartner } from "../_shared/domains/event/availability.ts";

const VALID_EVENT_STATUSES = ["scheduled", "cancelled", "completed"];
const _VALID_GENDERS = ["male", "female"];

// Fields allowed in event create/update
const EVENT_FIELDS = [
  "location_id",
  "start_time",
  "end_time",
  "max_participants",
  "min_confirmed_count",
  "title",
  "description",
  "image_urls",
  "contact_options",
  "vote_start_at",
  "vote_end_at",
  "visibility",
  "metadata",
] as const;

// Fields allowed in ticket update
// Fix #317: 이슈 스펙에 맞게 price/quantity만 허용
const TICKET_UPDATE_FIELDS = [
  "name",
  "description",
  "price",
  "quantity",
  "target_entry_group_ids",
  "required_verification_ids",
  "status",
] as const;

export const handler = async (
  req: Request,
  ctx: EFContext,
): Promise<Response> => {
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  const { supabase } = ctx;
  if (ctx.auth.type !== "user") {
    return errorResponse("Unexpected auth type", 500);
  }
  const userId = ctx.auth.userId;

  try {
    return await handleRequest(supabase, userId, req);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    return errorResponse(message, 500);
  }
};

minglitEdgeFunction(handler);

async function handleRequest(
  supabase: SupabaseClient,
  userId: string,
  req: Request,
): Promise<Response> {
  // Parse body
  const result = await parseAction(req);
  if (result instanceof Response) return result;
  const { action, body } = result;
  if (!action) return errorResponse("Missing action", 400);

  // ─── create ───
  if (action === "create") {
    return handleCreate(supabase, body, userId);
  }

  // ─── update ───
  if (action === "update") {
    return handleUpdate(supabase, body, userId);
  }

  // ─── update_status ───
  if (action === "update_status") {
    return handleUpdateStatus(supabase, body, userId);
  }

  // ─── update_tickets ───
  if (action === "update_tickets") {
    return handleUpdateTickets(supabase, body, userId);
  }

  // ─── create_ticket ───
  if (action === "create_ticket") {
    return handleCreateTicket(supabase, body, userId);
  }

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

  const eventData = body.event;
  if (
    typeof eventData !== "object" || eventData === null ||
    Array.isArray(eventData)
  ) {
    return errorResponse("Missing or invalid event object", 400);
  }
  const event = eventData as Record<string, unknown>;

  // Validate required time fields
  if (typeof event.start_time !== "string" || !event.start_time) {
    return errorResponse("Missing event start_time", 400);
  }
  if (typeof event.end_time !== "string" || !event.end_time) {
    return errorResponse("Missing event end_time", 400);
  }

  const startTime = new Date(event.start_time as string);
  const endTime = new Date(event.end_time as string);
  if (isNaN(startTime.getTime()) || isNaN(endTime.getTime())) {
    return errorResponse("Invalid date format for start_time or end_time", 400);
  }
  if (startTime >= endTime) {
    return errorResponse("start_time must be before end_time", 400);
  }
  if (startTime <= new Date()) {
    return errorResponse("start_time must be in the future", 400);
  }

  // Fetch party to verify ownership
  const { data: party, error: partyError } = await supabase
    .from("parties")
    .select("id, partner_id, location_id")
    .eq("id", partyId)
    .maybeSingle();

  if (partyError) return errorResponse("Failed to load party", 500);
  if (!party) return errorResponse("Party not found", 404);

  // Check partner permission
  const permCheck = await requirePartnerPermission(
    supabase,
    party.partner_id,
    userId,
    ["PARTY_MANAGE", "EVENT_MANAGE"],
  );
  if (permCheck) return permCheck;

  // ── Pre-validate child inputs before writing the event ──
  const directEntryGroups = body.entry_groups;
  const directEntryGroupSourceIds: Array<string | null> = [];
  const directEntryGroupSourceIdSet = new Set<string>();
  if (directEntryGroups !== undefined) {
    if (!Array.isArray(directEntryGroups)) {
      return errorResponse("entry_groups must be an array", 400);
    }
    for (let i = 0; i < directEntryGroups.length; i++) {
      const group = buildEntryGroupRecord(
        directEntryGroups[i],
        "__pending__",
        i,
      );
      if (group instanceof Response) return group;
      const sourceId = extractDirectEntryGroupSourceId(
        directEntryGroups[i],
        i,
      );
      if (sourceId instanceof Response) return sourceId;
      directEntryGroupSourceIds.push(sourceId);
      if (sourceId) {
        if (directEntryGroupSourceIdSet.has(sourceId)) {
          return errorResponse(
            `entry_groups[${i}].source_entry_group_id must be unique`,
            400,
          );
        }
        directEntryGroupSourceIdSet.add(sourceId);
      }
    }
  }

  const ticketInputs = body.tickets;
  if (ticketInputs !== undefined) {
    if (!Array.isArray(ticketInputs)) {
      return errorResponse("tickets must be an array", 400);
    }
    let templateRefCount = 0;
    for (let i = 0; i < ticketInputs.length; i++) {
      const t = ticketInputs[i] as Record<string, unknown>;
      if (typeof t !== "object" || t === null || Array.isArray(t)) {
        return errorResponse(`tickets[${i}] must be an object`, 400);
      }
      if (typeof t.template_id === "string") templateRefCount++;
    }
    const usesTemplateRefs = templateRefCount === ticketInputs.length;
    if (templateRefCount > 0 && !usesTemplateRefs) {
      return errorResponse(
        "tickets must use either template_id references or direct ticket objects, not both",
        400,
      );
    }
    for (let i = 0; i < ticketInputs.length; i++) {
      const t = ticketInputs[i] as Record<string, unknown>;
      if (usesTemplateRefs && typeof t.template_id !== "string") {
        return errorResponse(`tickets[${i}].template_id is required`, 400);
      }
      if (
        usesTemplateRefs &&
        (typeof t.quantity !== "number" || t.quantity < 0)
      ) {
        return errorResponse(
          `tickets[${i}].quantity must be a non-negative number`,
          400,
        );
      }
      if (!usesTemplateRefs) {
        const ticket = buildTicketRecord(t, "__pending__");
        if (ticket instanceof Response) return ticket;
        if (directEntryGroups !== undefined) {
          const targetCheck = validateDirectTicketTargets(
            t,
            i,
            directEntryGroupSourceIdSet,
          );
          if (targetCheck) return targetCheck;
        }
      }
    }
  }

  // ── DB writes ──

  const locationIdInput = event.location_id;
  let locationId = party.location_id;
  if (locationIdInput !== undefined && typeof locationIdInput !== "string") {
    return errorResponse("event.location_id must be a string", 400);
  }
  if (typeof locationIdInput === "string" && locationIdInput) {
    const { data: location, error: locationError } = await supabase
      .from("locations")
      .select("id, partner_id")
      .eq("id", locationIdInput)
      .maybeSingle();

    if (locationError) return errorResponse("Failed to verify location", 500);
    if (!location) return errorResponse("Location not found", 404);
    if (location.partner_id !== party.partner_id) {
      return errorResponse(
        "Forbidden: location belongs to another partner",
        403,
      );
    }
    locationId = locationIdInput;
  }

  // Build event record
  const eventRecord: Record<string, unknown> = {
    party_id: partyId,
    location_id: locationId,
  };
  for (const field of EVENT_FIELDS) {
    if (field === "location_id") continue;
    if (event[field] !== undefined) {
      eventRecord[field] = event[field];
    }
  }

  // Insert event
  const { data: newEvent, error: eventInsertError } = await supabase
    .from("events")
    .insert(eventRecord)
    .select("id")
    .single();

  if (eventInsertError) {
    return errorResponse(
      `Failed to create event: ${eventInsertError.message}`,
      500,
    );
  }

  const eventId = newEvent.id as string;

  const sourceToGroupMap = new Map<string, string>();

  if (directEntryGroups !== undefined) {
    const entryGroups: Record<string, unknown>[] = [];
    for (let i = 0; i < directEntryGroups.length; i++) {
      const group = buildEntryGroupRecord(directEntryGroups[i], eventId, i);
      if (group instanceof Response) return group;
      entryGroups.push(group);
    }

    if (entryGroups.length > 0) {
      const { data: insertedGroups, error: egError } = await supabase
        .from("entry_groups")
        .insert(entryGroups)
        .select("id");

      if (egError) {
        return errorResponse(
          `Failed to create entry groups: ${egError.message}`,
          500,
        );
      }
      if (!insertedGroups || insertedGroups.length !== entryGroups.length) {
        return errorResponse("Failed to resolve created entry groups", 500);
      }
      for (let i = 0; i < insertedGroups.length; i++) {
        const sourceId = directEntryGroupSourceIds[i];
        if (sourceId) {
          sourceToGroupMap.set(
            sourceId,
            (insertedGroups[i] as Record<string, unknown>).id as string,
          );
        }
      }
    }
  } else {
    // Copy entry_group_templates → entry_groups
    // Fix #317: ID를 포함해서 조회하여 target_entry_group_ids 재매핑에 사용
    const { data: templates, error: tplError } = await supabase
      .from("entry_group_templates")
      .select(
        "id, label, gender, birth_year_min, birth_year_max, required_verification_ids",
      )
      .eq("party_id", partyId);

    if (tplError) {
      return errorResponse(
        `Failed to fetch entry group templates: ${tplError.message}`,
        500,
      );
    }

    if (templates && templates.length > 0) {
      const entryGroups = templates.map((t: Record<string, unknown>) => ({
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
        return errorResponse(
          `Failed to create entry groups: ${egError.message}`,
          500,
        );
      }

      // Build mapping from template ID to new entry_group ID (same order)
      if (insertedGroups) {
        for (let i = 0; i < templates.length; i++) {
          sourceToGroupMap.set(
            templates[i].id as string,
            (insertedGroups[i] as Record<string, unknown>).id as string,
          );
        }
      }
    }
  }

  // Create tickets from ticket_templates
  if (Array.isArray(ticketInputs) && ticketInputs.length > 0) {
    const usesTemplateRefs = ticketInputs.every((t) =>
      typeof (t as Record<string, unknown>).template_id === "string"
    );

    let tickets: Record<string, unknown>[];
    if (usesTemplateRefs) {
      // Fetch referenced ticket templates
      const templateIds = ticketInputs.map((t: Record<string, unknown>) =>
        t.template_id as string
      );
      const { data: ticketTemplates, error: ttError } = await supabase
        .from("ticket_templates")
        .select(
          "id, name, description, price, target_entry_group_ids, required_verification_ids",
        )
        .eq("party_id", partyId)
        .in("id", templateIds);

      if (ttError) {
        return errorResponse(
          `Failed to fetch ticket templates: ${ttError.message}`,
          500,
        );
      }

      const templateMap = new Map(
        (ticketTemplates ?? []).map((t: Record<string, unknown>) => [t.id, t]),
      );

      // Verify all template_ids exist
      for (let i = 0; i < ticketInputs.length; i++) {
        const input = ticketInputs[i] as Record<string, unknown>;
        if (!templateMap.has(input.template_id)) {
          return errorResponse(
            `tickets[${i}].template_id not found in party templates`,
            400,
          );
        }
      }

      tickets = ticketInputs.map((input: Record<string, unknown>) => {
        const tpl = templateMap.get(input.template_id) as Record<
          string,
          unknown
        >;
        // Fix #317: target_entry_group_ids를 새 entry_group ID로 재매핑
        const originalTargetIds = (tpl.target_entry_group_ids as string[]) ??
          [];
        const remappedTargetIds = originalTargetIds
          .map((id: string) => sourceToGroupMap.get(id))
          .filter((id): id is string => id !== undefined);

        return {
          event_id: eventId,
          name: tpl.name,
          description: tpl.description ?? null,
          price: tpl.price ?? 0,
          quantity: input.quantity,
          target_entry_group_ids: remappedTargetIds,
          required_verification_ids: tpl.required_verification_ids ?? [],
        };
      });
    } else {
      tickets = [];
      for (let i = 0; i < ticketInputs.length; i++) {
        const input = ticketInputs[i] as Record<string, unknown>;
        const ticket = buildTicketRecord(input, eventId);
        if (ticket instanceof Response) {
          return ticket;
        }
        if (directEntryGroups !== undefined) {
          ticket.target_entry_group_ids = (
            ticket.target_entry_group_ids as string[]
          ).map((id) => sourceToGroupMap.get(id) ?? id);
        }
        tickets.push(ticket);
      }
    }

    const { error: ticketInsertError } = await supabase
      .from("tickets")
      .insert(tickets);

    if (ticketInsertError) {
      return errorResponse(
        `Failed to create tickets: ${ticketInsertError.message}`,
        500,
      );
    }
  }

  return successResponse({ success: true, event_id: eventId });
}

async function handleCreateTicket(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const ticketData = body.ticket;
  if (
    typeof ticketData !== "object" || ticketData === null ||
    Array.isArray(ticketData)
  ) {
    return errorResponse("Missing or invalid ticket object", 400);
  }
  const input = ticketData as Record<string, unknown>;
  const eventId = input.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing ticket.event_id", 400);
  }

  const eventCheck = await verifyEventPermission(supabase, eventId, userId);
  if (eventCheck instanceof Response) return eventCheck;

  const ticket = buildTicketRecord(input, eventId);
  if (ticket instanceof Response) return ticket;

  const { data, error } = await supabase
    .from("tickets")
    .insert(ticket)
    .select("id")
    .single();

  if (error) {
    return errorResponse(`Failed to create ticket: ${error.message}`, 500);
  }

  return successResponse({ success: true, ticket_id: data.id });
}

async function handleUpdate(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing event_id", 400);
  }

  // Fix #2110: Fetch OLD event values for change_log before/after snapshot.
  const { data: oldEvent, error: fetchError } = await supabase
    .from("events")
    .select("id, party_id, start_time, end_time, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load event", 500);
  if (!oldEvent) return errorResponse("Event not found", 404);

  const partnerId = extractRelatedPartnerId(oldEvent);
  if (!partnerId) return errorResponse("Failed to resolve partner", 500);

  // Check partner permission
  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    ["PARTY_MANAGE", "EVENT_MANAGE"],
  );
  if (permCheck) return permCheck;

  // Build update fields
  const eventData = body.event;
  if (
    typeof eventData !== "object" || eventData === null ||
    Array.isArray(eventData)
  ) {
    return errorResponse("Missing or invalid event object", 400);
  }
  const input = eventData as Record<string, unknown>;

  const updates: Record<string, unknown> = {};
  for (const field of EVENT_FIELDS) {
    if (input[field] !== undefined) {
      updates[field] = input[field];
    }
  }

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update", 400);
  }

  if (updates.location_id !== undefined) {
    if (typeof updates.location_id !== "string" || !updates.location_id) {
      return errorResponse("event.location_id must be a string", 400);
    }

    const { data: location, error: locationError } = await supabase
      .from("locations")
      .select("id, partner_id")
      .eq("id", updates.location_id)
      .maybeSingle();

    if (locationError) return errorResponse("Failed to verify location", 500);
    if (!location) return errorResponse("Location not found", 404);
    if (location.partner_id !== partnerId) {
      return errorResponse(
        "Forbidden: location belongs to another partner",
        403,
      );
    }
  }

  // Validate time fields if provided
  if (updates.start_time !== undefined || updates.end_time !== undefined) {
    const st = updates.start_time
      ? new Date(updates.start_time as string)
      : null;
    const et = updates.end_time ? new Date(updates.end_time as string) : null;
    if (st && isNaN(st.getTime())) {
      return errorResponse("Invalid start_time format", 400);
    }
    if (et && isNaN(et.getTime())) {
      return errorResponse("Invalid end_time format", 400);
    }
    // Fix #317: Cross-validate when both are provided
    if (st && et && st >= et) {
      return errorResponse("start_time must be before end_time", 400);
    }
  }

  const { error: updateError } = await supabase
    .from("events")
    .update(updates)
    .eq("id", eventId);

  if (updateError) {
    return errorResponse(`Failed to update event: ${updateError.message}`, 500);
  }

  // Fix #2110: Record change_log when schedule changes and reason is provided.
  // spec §알림 발송 정책: event_change_log must be persisted alongside push.
  // Push notification is already triggered by trigger_produce_event_events().
  // Constraint: reason-enriched notification body + SMS fan-out deferred
  // (tracked separately — notification-worker extension needed).
  const reason = typeof body.reason === "string" ? body.reason.trim() : null;
  const isScheduleChanged = (updates.start_time !== undefined &&
    updates.start_time !== (oldEvent as Record<string, unknown>).start_time) ||
    (updates.end_time !== undefined &&
      updates.end_time !== (oldEvent as Record<string, unknown>).end_time);

  if (reason && isScheduleChanged) {
    const changeLog: Record<string, unknown> = {
      event_id: eventId,
      changed_by: userId,
      reason,
      previous_start_time: (oldEvent as Record<string, unknown>).start_time,
      new_start_time: updates.start_time ??
        (oldEvent as Record<string, unknown>).start_time,
      previous_end_time: (oldEvent as Record<string, unknown>).end_time,
      new_end_time: updates.end_time ??
        (oldEvent as Record<string, unknown>).end_time,
    };
    // Use service_role client — event_change_logs has no INSERT RLS for users.
    const { error: logError } = await supabase
      .from("event_change_logs")
      .insert(changeLog);
    if (logError) {
      // Log insert failure must not block the update response — the event is
      // already saved. Log and continue.
      console.error("event_change_logs insert failed:", logError.message);
    }
  }

  return successResponse({ success: true });
}

async function handleUpdateStatus(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing event_id", 400);
  }

  const status = body.status;
  if (typeof status !== "string" || !status) {
    return errorResponse("Missing status", 400);
  }

  // completed는 시스템 전용 — 파트너가 직접 변경 불가
  if (status === "completed") {
    return errorResponse("Cannot set status to completed — system only", 400);
  }

  if (!VALID_EVENT_STATUSES.includes(status)) {
    return errorResponse(
      `Invalid status. Must be one of: ${VALID_EVENT_STATUSES.join(", ")}`,
      400,
    );
  }

  // Fetch event → party → partner
  const { data: event, error: fetchError } = await supabase
    .from("events")
    .select("id, status, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  // Only scheduled → cancelled is allowed (state machine guard)
  if (!isEventEditableByPartner(event.status)) {
    return errorResponse(
      `Cannot change status from ${event.status} to ${status}`,
      400,
    );
  }

  const partnerId = extractRelatedPartnerId(event);
  if (!partnerId) return errorResponse("Failed to resolve partner", 500);

  // Check partner permission
  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    ["PARTY_MANAGE", "EVENT_MANAGE"],
  );
  if (permCheck) return permCheck;

  const { error: updateError } = await supabase
    .from("events")
    .update({ status })
    .eq("id", eventId);

  if (updateError) {
    return errorResponse(
      `Failed to update event status: ${updateError.message}`,
      500,
    );
  }

  return successResponse({ success: true });
}

async function handleUpdateTickets(
  supabase: SupabaseClient,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing event_id", 400);
  }

  const ticketUpdates = body.tickets;
  if (!Array.isArray(ticketUpdates) || ticketUpdates.length === 0) {
    return errorResponse("Missing or empty tickets array", 400);
  }

  // Validate ticket update inputs
  for (let i = 0; i < ticketUpdates.length; i++) {
    const t = ticketUpdates[i] as Record<string, unknown>;
    if (typeof t !== "object" || t === null || Array.isArray(t)) {
      return errorResponse(`tickets[${i}] must be an object`, 400);
    }
    if (typeof t.ticket_id !== "string" || !t.ticket_id) {
      return errorResponse(`tickets[${i}].ticket_id is required`, 400);
    }
    if (t.price !== undefined && (typeof t.price !== "number" || t.price < 0)) {
      return errorResponse(`tickets[${i}].price must be >= 0`, 400);
    }
    if (
      t.quantity !== undefined &&
      (typeof t.quantity !== "number" || t.quantity < 0)
    ) {
      return errorResponse(
        `tickets[${i}].quantity must be a non-negative number`,
        400,
      );
    }
  }

  // Fetch event → party → partner
  const { data: event, error: fetchError } = await supabase
    .from("events")
    .select("id, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  const partnerId = extractRelatedPartnerId(event);
  if (!partnerId) return errorResponse("Failed to resolve partner", 500);

  // Check partner permission
  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    ["PARTY_MANAGE", "EVENT_MANAGE"],
  );
  if (permCheck) return permCheck;

  // Fetch existing tickets to validate sold_count
  const ticketIds = ticketUpdates.map((t: Record<string, unknown>) =>
    t.ticket_id as string
  );
  const { data: existingTickets, error: ticketFetchError } = await supabase
    .from("tickets")
    .select("id, sold_count, event_id")
    .eq("event_id", eventId)
    .in("id", ticketIds);

  if (ticketFetchError) {
    return errorResponse("Failed to fetch tickets", 500);
  }

  const ticketMap = new Map(
    (existingTickets ?? []).map((t: Record<string, unknown>) => [t.id, t]),
  );

  // Validate all ticket_ids exist and belong to this event
  for (let i = 0; i < ticketUpdates.length; i++) {
    const input = ticketUpdates[i] as Record<string, unknown>;
    const existing = ticketMap.get(input.ticket_id);
    if (!existing) {
      return errorResponse(
        `tickets[${i}].ticket_id not found in this event`,
        400,
      );
    }
    // Validate quantity >= sold_count
    if (input.quantity !== undefined) {
      const soldCount = (existing as Record<string, unknown>)
        .sold_count as number;
      if ((input.quantity as number) < soldCount) {
        return errorResponse(
          `tickets[${i}].quantity (${input.quantity}) cannot be less than sold_count (${soldCount})`,
          400,
        );
      }
    }
  }

  // Apply updates
  for (const input of ticketUpdates) {
    const t = input as Record<string, unknown>;
    const updates: Record<string, unknown> = {};
    for (const field of TICKET_UPDATE_FIELDS) {
      if (t[field] !== undefined) {
        updates[field] = t[field];
      }
    }

    if (Object.keys(updates).length === 0) continue;

    const { error: updateError } = await supabase
      .from("tickets")
      .update(updates)
      .eq("id", t.ticket_id)
      .eq("event_id", eventId);

    if (updateError) {
      return errorResponse(
        `Failed to update ticket: ${updateError.message}`,
        500,
      );
    }
  }

  return successResponse({ success: true });
}

// ─── Helpers ───

function extractRelatedPartnerId(row: { parties?: unknown }): string | null {
  const relation = row.parties;
  const party = Array.isArray(relation) ? relation[0] : relation;
  if (typeof party !== "object" || party === null) return null;

  const partnerId = (party as Record<string, unknown>).partner_id;
  return typeof partnerId === "string" && partnerId ? partnerId : null;
}

async function verifyEventPermission(
  supabase: SupabaseClient,
  eventId: string,
  userId: string,
): Promise<true | Response> {
  const { data: event, error: fetchError } = await supabase
    .from("events")
    .select("id, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  const partnerId = extractRelatedPartnerId(event);
  if (!partnerId) return errorResponse("Failed to resolve partner", 500);
  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    [
      "PARTY_MANAGE",
      "EVENT_MANAGE",
    ],
  );
  if (permCheck) return permCheck;
  return true;
}

function extractDirectEntryGroupSourceId(
  input: unknown,
  index: number,
): string | null | Response {
  if (typeof input !== "object" || input === null || Array.isArray(input)) {
    return errorResponse(`entry_groups[${index}] must be an object`, 400);
  }
  const group = input as Record<string, unknown>;
  const sourceId = [
    group.source_entry_group_id,
    group.source_template_id,
    group.template_id,
    group.id,
  ].find((value) => value !== undefined && value !== null && value !== "");
  if (sourceId === undefined) {
    return null;
  }
  if (typeof sourceId !== "string") {
    return errorResponse(
      `entry_groups[${index}].source_entry_group_id must be a string`,
      400,
    );
  }
  return sourceId;
}

function validateDirectTicketTargets(
  input: Record<string, unknown>,
  ticketIndex: number,
  sourceIds: Set<string>,
): Response | null {
  const targetIds = input.target_entry_group_ids;
  if (targetIds === undefined || targetIds === null) return null;
  if (!Array.isArray(targetIds)) {
    return errorResponse(
      `tickets[${ticketIndex}].target_entry_group_ids must be an array`,
      400,
    );
  }
  for (let i = 0; i < targetIds.length; i++) {
    const targetId = targetIds[i];
    if (typeof targetId !== "string" || !targetId) {
      return errorResponse(
        `tickets[${ticketIndex}].target_entry_group_ids[${i}] must be a string`,
        400,
      );
    }
    if (!sourceIds.has(targetId)) {
      return errorResponse(
        `tickets[${ticketIndex}].target_entry_group_ids[${i}] must reference entry_groups[].source_entry_group_id`,
        400,
      );
    }
  }
  return null;
}

function buildEntryGroupRecord(
  input: unknown,
  eventId: string,
  index: number,
): Record<string, unknown> | Response {
  if (typeof input !== "object" || input === null || Array.isArray(input)) {
    return errorResponse(`entry_groups[${index}] must be an object`, 400);
  }

  const group = input as Record<string, unknown>;
  if (
    group.gender !== undefined &&
    group.gender !== null &&
    (typeof group.gender !== "string" || !_VALID_GENDERS.includes(group.gender))
  ) {
    return errorResponse(
      `entry_groups[${index}].gender must be one of: ${
        _VALID_GENDERS.join(", ")
      }`,
      400,
    );
  }

  return {
    event_id: eventId,
    label: group.label ?? null,
    gender: group.gender ?? null,
    birth_year_min: group.birth_year_min ?? null,
    birth_year_max: group.birth_year_max ?? null,
    required_verification_ids: group.required_verification_ids ?? [],
  };
}

function buildTicketRecord(
  input: Record<string, unknown>,
  eventId: string,
): Record<string, unknown> | Response {
  if (typeof input.name !== "string" || !input.name.trim()) {
    return errorResponse("Missing ticket name", 400);
  }
  if (
    input.price !== undefined &&
    (typeof input.price !== "number" || input.price < 0)
  ) {
    return errorResponse("ticket.price must be >= 0", 400);
  }
  if (
    input.quantity !== undefined &&
    (typeof input.quantity !== "number" || input.quantity < 0)
  ) {
    return errorResponse("ticket.quantity must be a non-negative number", 400);
  }
  const targetIds = input.target_entry_group_ids ?? [];
  if (!Array.isArray(targetIds)) {
    return errorResponse("ticket.target_entry_group_ids must be an array", 400);
  }
  for (let i = 0; i < targetIds.length; i++) {
    if (typeof targetIds[i] !== "string" || !targetIds[i]) {
      return errorResponse(
        `ticket.target_entry_group_ids[${i}] must be a string`,
        400,
      );
    }
  }

  return {
    event_id: eventId,
    name: input.name,
    description: input.description ?? null,
    price: input.price ?? 0,
    quantity: input.quantity ?? 0,
    target_entry_group_ids: targetIds,
    required_verification_ids: input.required_verification_ids ?? [],
    status: input.status ?? "on_sale",
  };
}
