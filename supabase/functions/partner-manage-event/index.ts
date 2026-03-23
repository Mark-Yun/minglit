// partner-manage-event — Event/ticket/entry-group CRUD for partners
// Issue #317: RLS write strategy 전환 — 이벤트/티켓 CRUD

import { createClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

const VALID_EVENT_STATUSES = ["scheduled", "cancelled", "completed"];
const VALID_GENDERS = ["male", "female"];

// Fields allowed in event create/update
const EVENT_FIELDS = [
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
] as const;

// Fields allowed in ticket update
const TICKET_UPDATE_FIELDS = [
  "price",
  "quantity",
  "name",
  "description",
  "status",
  "target_entry_group_ids",
  "required_verification_ids",
] as const;

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
  // 1. Environment check
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Missing server configuration", 500);
  }

  // 2. Auth
  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const userId = auth;

  // 3. Parse body
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

  // 4. Supabase client (service role)
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

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

  return errorResponse(`Unknown action: ${action}`, 400);
}

// ─── Action Handlers ───

async function handleCreate(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const partyId = body.party_id;
  if (typeof partyId !== "string" || !partyId) {
    return errorResponse("Missing party_id", 400);
  }

  const eventData = body.event;
  if (typeof eventData !== "object" || eventData === null || Array.isArray(eventData)) {
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
  const permCheck = await checkPartnerPermission(supabase, party.partner_id, userId);
  if (permCheck instanceof Response) return permCheck;

  // ── Pre-validate ticket template references ──
  const ticketInputs = body.tickets;
  if (ticketInputs !== undefined) {
    if (!Array.isArray(ticketInputs)) {
      return errorResponse("tickets must be an array", 400);
    }
    for (let i = 0; i < ticketInputs.length; i++) {
      const t = ticketInputs[i] as Record<string, unknown>;
      if (typeof t !== "object" || t === null || Array.isArray(t)) {
        return errorResponse(`tickets[${i}] must be an object`, 400);
      }
      if (typeof t.template_id !== "string" || !t.template_id) {
        return errorResponse(`tickets[${i}].template_id is required`, 400);
      }
      if (typeof t.quantity !== "number" || t.quantity < 0) {
        return errorResponse(`tickets[${i}].quantity must be a non-negative number`, 400);
      }
    }
  }

  // ── DB writes ──

  // Build event record
  const eventRecord: Record<string, unknown> = {
    party_id: partyId,
    location_id: party.location_id,
  };
  for (const field of EVENT_FIELDS) {
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
    return errorResponse(`Failed to create event: ${eventInsertError.message}`, 500);
  }

  const eventId = newEvent.id as string;

  // Copy entry_group_templates → entry_groups
  const { data: templates, error: tplError } = await supabase
    .from("entry_group_templates")
    .select("label, gender, birth_year_min, birth_year_max, required_verification_ids")
    .eq("party_id", partyId);

  if (tplError) {
    return errorResponse(`Failed to fetch entry group templates: ${tplError.message}`, 500);
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

    const { error: egError } = await supabase
      .from("entry_groups")
      .insert(entryGroups);

    if (egError) {
      return errorResponse(`Failed to create entry groups: ${egError.message}`, 500);
    }
  }

  // Create tickets from ticket_templates
  if (Array.isArray(ticketInputs) && ticketInputs.length > 0) {
    // Fetch referenced ticket templates
    const templateIds = ticketInputs.map((t: Record<string, unknown>) => t.template_id as string);
    const { data: ticketTemplates, error: ttError } = await supabase
      .from("ticket_templates")
      .select("id, name, description, price, target_entry_group_ids, required_verification_ids")
      .eq("party_id", partyId)
      .in("id", templateIds);

    if (ttError) {
      return errorResponse(`Failed to fetch ticket templates: ${ttError.message}`, 500);
    }

    const templateMap = new Map(
      (ticketTemplates ?? []).map((t: Record<string, unknown>) => [t.id, t]),
    );

    // Verify all template_ids exist
    for (let i = 0; i < ticketInputs.length; i++) {
      const input = ticketInputs[i] as Record<string, unknown>;
      if (!templateMap.has(input.template_id)) {
        return errorResponse(`tickets[${i}].template_id not found in party templates`, 400);
      }
    }

    const tickets = ticketInputs.map((input: Record<string, unknown>) => {
      const tpl = templateMap.get(input.template_id) as Record<string, unknown>;
      return {
        event_id: eventId,
        name: tpl.name,
        description: tpl.description ?? null,
        price: tpl.price ?? 0,
        quantity: input.quantity,
        target_entry_group_ids: tpl.target_entry_group_ids ?? [],
        required_verification_ids: tpl.required_verification_ids ?? [],
      };
    });

    const { error: ticketInsertError } = await supabase
      .from("tickets")
      .insert(tickets);

    if (ticketInsertError) {
      return errorResponse(`Failed to create tickets: ${ticketInsertError.message}`, 500);
    }
  }

  return successResponse({ success: true, event_id: eventId });
}

async function handleUpdate(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
  userId: string,
): Promise<Response> {
  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) {
    return errorResponse("Missing event_id", 400);
  }

  // Fetch event → party → partner
  const { data: event, error: fetchError } = await supabase
    .from("events")
    .select("id, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  const partnerId = (event.parties as Record<string, unknown>).partner_id as string;

  // Check partner permission
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  // Build update fields
  const eventData = body.event;
  if (typeof eventData !== "object" || eventData === null || Array.isArray(eventData)) {
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

  // Validate time fields if provided
  if (updates.start_time !== undefined || updates.end_time !== undefined) {
    const st = updates.start_time ? new Date(updates.start_time as string) : null;
    const et = updates.end_time ? new Date(updates.end_time as string) : null;
    if (st && isNaN(st.getTime())) {
      return errorResponse("Invalid start_time format", 400);
    }
    if (et && isNaN(et.getTime())) {
      return errorResponse("Invalid end_time format", 400);
    }
  }

  const { error: updateError } = await supabase
    .from("events")
    .update(updates)
    .eq("id", eventId);

  if (updateError) {
    return errorResponse(`Failed to update event: ${updateError.message}`, 500);
  }

  return successResponse({ success: true });
}

async function handleUpdateStatus(
  supabase: ReturnType<typeof createClient>,
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
    return errorResponse(`Invalid status. Must be one of: ${VALID_EVENT_STATUSES.join(", ")}`, 400);
  }

  // Fetch event → party → partner
  const { data: event, error: fetchError } = await supabase
    .from("events")
    .select("id, status, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  // Only scheduled → cancelled is allowed
  if (event.status !== "scheduled") {
    return errorResponse(`Cannot change status from ${event.status} to ${status}`, 400);
  }

  const partnerId = (event.parties as Record<string, unknown>).partner_id as string;

  // Check partner permission
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  const { error: updateError } = await supabase
    .from("events")
    .update({ status })
    .eq("id", eventId);

  if (updateError) {
    return errorResponse(`Failed to update event status: ${updateError.message}`, 500);
  }

  return successResponse({ success: true });
}

async function handleUpdateTickets(
  supabase: ReturnType<typeof createClient>,
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
    if (t.quantity !== undefined && (typeof t.quantity !== "number" || t.quantity < 0)) {
      return errorResponse(`tickets[${i}].quantity must be a non-negative number`, 400);
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

  const partnerId = (event.parties as Record<string, unknown>).partner_id as string;

  // Check partner permission
  const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
  if (permCheck instanceof Response) return permCheck;

  // Fetch existing tickets to validate sold_count
  const ticketIds = ticketUpdates.map((t: Record<string, unknown>) => t.ticket_id as string);
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
      return errorResponse(`tickets[${i}].ticket_id not found in this event`, 400);
    }
    // Validate quantity >= sold_count
    if (input.quantity !== undefined) {
      const soldCount = (existing as Record<string, unknown>).sold_count as number;
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
      return errorResponse(`Failed to update ticket: ${updateError.message}`, 500);
    }
  }

  return successResponse({ success: true });
}

// ─── Helpers ───

async function checkPartnerPermission(
  supabase: ReturnType<typeof createClient>,
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
  const hasPermission = permissions.includes("PARTY_MANAGE") || permissions.includes("EVENT_MANAGE");
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}
