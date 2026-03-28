// partner-manage-party — Party/location/template CRUD for partners
// Issue #316: RLS write strategy 전환

import { createServiceClient } from "../_shared/supabase_client.ts";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

const VALID_STATUSES = ["draft", "active", "closed"];
const VALID_GENDERS = ["male", "female"];

// Fields allowed in party create/update
const PARTY_FIELDS = [
  "title",
  "description",
  "image_urls",
  "contact_options",
  "required_verification_ids",
  "min_confirmed_count",
  "max_participants",
  "balance_config",
  "status",
] as const;

// Fields allowed in location create/update
const LOCATION_FIELDS = [
  "name",
  "address",
  "address_detail",
  "region_1",
  "region_2",
  "region_3",
  "directions_guide",
  "postal_code",
  "geo_point",
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
  // 1. Environment check (handled by createServiceClient)

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
  const supabase = createServiceClient();

  // ─── create ───
  if (action === "create") {
    // Require partner_id from client (supports multi-partner users)
    const partnerId = body.partner_id;
    if (typeof partnerId !== "string" || !partnerId) {
      return errorResponse("Missing partner_id", 400);
    }

    // Validate party fields
    const partyData = body.party;
    if (typeof partyData !== "object" || partyData === null || Array.isArray(partyData)) {
      return errorResponse("Missing or invalid party object", 400);
    }
    const party = partyData as Record<string, unknown>;

    if (typeof party.title !== "string" || !party.title.trim()) {
      return errorResponse("Missing party title", 400);
    }

    // Check partner permission
    const permCheck = await checkPartnerPermission(supabase, partnerId, userId);
    if (permCheck instanceof Response) return permCheck;

    // ── Pre-validate all payloads before any DB writes ──

    // Validate status if provided
    if (party.status !== undefined) {
      if (typeof party.status !== "string" || !VALID_STATUSES.includes(party.status)) {
        return errorResponse(`Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`, 400);
      }
    }

    // Validate location input if new location
    let newLocationInput: Record<string, unknown> | null = null;
    const existingLocationId = body.location_id;
    if (body.location && typeof body.location === "object" && !Array.isArray(body.location)) {
      newLocationInput = body.location as Record<string, unknown>;
      if (typeof newLocationInput.name !== "string" || !newLocationInput.name.trim()) {
        return errorResponse("Missing location name", 400);
      }
      if (typeof newLocationInput.address !== "string" || !newLocationInput.address.trim()) {
        return errorResponse("Missing location address", 400);
      }
    }

    // Validate entry_group_templates
    const entryGroupTemplates = body.entry_group_templates;
    if (Array.isArray(entryGroupTemplates) && entryGroupTemplates.length > 0) {
      const validationError = validateEntryGroupTemplates(entryGroupTemplates);
      if (validationError) return validationError;
    }

    // Validate ticket_templates
    const ticketTemplates = body.ticket_templates;
    if (Array.isArray(ticketTemplates) && ticketTemplates.length > 0) {
      const validationError = validateTicketTemplates(ticketTemplates);
      if (validationError) return validationError;
    }

    // ── All validations passed — now perform DB writes ──

    // Build location record if provided
    let locationId: string | null = null;
    if (typeof existingLocationId === "string" && existingLocationId) {
      // Use existing location — verify it belongs to this partner
      const { data: loc, error: locError } = await supabase
        .from("locations")
        .select("id, partner_id")
        .eq("id", existingLocationId)
        .maybeSingle();

      if (locError) return errorResponse("Failed to verify location", 500);
      if (!loc) return errorResponse("Location not found", 404);
      if (loc.partner_id !== partnerId) {
        return errorResponse("Forbidden: location belongs to another partner", 403);
      }
      locationId = existingLocationId;
    } else if (newLocationInput) {
      const locRecord: Record<string, unknown> = { partner_id: partnerId };
      for (const field of LOCATION_FIELDS) {
        if (newLocationInput[field] !== undefined) {
          locRecord[field] = newLocationInput[field];
        }
      }

      const { data: newLoc, error: locInsertError } = await supabase
        .from("locations")
        .insert(locRecord)
        .select("id")
        .single();

      if (locInsertError) {
        return errorResponse(`Failed to create location: ${locInsertError.message}`, 500);
      }
      locationId = newLoc.id;
    }

    // Build party record — only allow whitelisted fields
    const partyRecord: Record<string, unknown> = {
      partner_id: partnerId,
    };
    if (locationId) partyRecord.location_id = locationId;

    for (const field of PARTY_FIELDS) {
      if (party[field] !== undefined) {
        partyRecord[field] = party[field];
      }
    }

    // Insert party
    const { data: newParty, error: partyInsertError } = await supabase
      .from("parties")
      .insert(partyRecord)
      .select("id")
      .single();

    if (partyInsertError) {
      return errorResponse(`Failed to create party: ${partyInsertError.message}`, 500);
    }

    const partyId = newParty.id as string;

    // Insert entry_group_templates if provided (already validated above)
    if (Array.isArray(entryGroupTemplates) && entryGroupTemplates.length > 0) {
      const egt = entryGroupTemplates.map((t: Record<string, unknown>) => ({
        party_id: partyId,
        label: t.label ?? null,
        gender: t.gender ?? null,
        birth_year_min: t.birth_year_min ?? null,
        birth_year_max: t.birth_year_max ?? null,
        required_verification_ids: t.required_verification_ids ?? [],
      }));

      const { error: egtError } = await supabase
        .from("entry_group_templates")
        .insert(egt);

      if (egtError) {
        return errorResponse(`Failed to create entry group templates: ${egtError.message}`, 500);
      }
    }

    // Insert ticket_templates if provided (already validated above)
    if (Array.isArray(ticketTemplates) && ticketTemplates.length > 0) {
      const tt = ticketTemplates.map((t: Record<string, unknown>) => ({
        party_id: partyId,
        name: t.name,
        description: t.description ?? null,
        price: t.price ?? 0,
        quantity: t.quantity,
        target_entry_group_ids: t.target_entry_group_ids ?? [],
        required_verification_ids: t.required_verification_ids ?? [],
      }));

      const { error: ttError } = await supabase
        .from("ticket_templates")
        .insert(tt);

      if (ttError) {
        return errorResponse(`Failed to create ticket templates: ${ttError.message}`, 500);
      }
    }

    return successResponse({ success: true, party_id: partyId });
  }

  // ─── update ───
  if (action === "update") {
    const partyId = body.party_id;
    if (typeof partyId !== "string" || !partyId) {
      return errorResponse("Missing party_id", 400);
    }

    // Fetch party to verify ownership
    const { data: existingParty, error: fetchError } = await supabase
      .from("parties")
      .select("id, partner_id")
      .eq("id", partyId)
      .maybeSingle();

    if (fetchError) return errorResponse("Failed to load party", 500);
    if (!existingParty) return errorResponse("Party not found", 404);

    // Check partner permission
    const permCheck = await checkPartnerPermission(supabase, existingParty.partner_id, userId);
    if (permCheck instanceof Response) return permCheck;

    // Build party updates
    const partyData = body.party;
    const partyUpdates: Record<string, unknown> = {};
    if (typeof partyData === "object" && partyData !== null && !Array.isArray(partyData)) {
      const party = partyData as Record<string, unknown>;
      for (const field of PARTY_FIELDS) {
        if (party[field] !== undefined) {
          partyUpdates[field] = party[field];
        }
      }

      // Validate status if provided
      if (partyUpdates.status !== undefined) {
        if (typeof partyUpdates.status !== "string" || !VALID_STATUSES.includes(partyUpdates.status)) {
          return errorResponse(`Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`, 400);
        }
      }
    }

    // Update party fields if any
    if (Object.keys(partyUpdates).length > 0) {
      const { error: updateError } = await supabase
        .from("parties")
        .update(partyUpdates)
        .eq("id", partyId);

      if (updateError) {
        return errorResponse(`Failed to update party: ${updateError.message}`, 500);
      }
    }

    // Update location if provided
    const locationData = body.location;
    if (typeof locationData === "object" && locationData !== null && !Array.isArray(locationData)) {
      const locInput = locationData as Record<string, unknown>;

      // Check if party has a location_id to update
      const { data: partyWithLoc, error: locFetchError } = await supabase
        .from("parties")
        .select("location_id")
        .eq("id", partyId)
        .single();

      if (locFetchError) return errorResponse("Failed to fetch party location", 500);

      if (partyWithLoc.location_id) {
        // Update existing location
        const locUpdates: Record<string, unknown> = {};
        for (const field of LOCATION_FIELDS) {
          if (locInput[field] !== undefined) {
            locUpdates[field] = locInput[field];
          }
        }

        if (Object.keys(locUpdates).length > 0) {
          const { error: locUpdateError } = await supabase
            .from("locations")
            .update(locUpdates)
            .eq("id", partyWithLoc.location_id);

          if (locUpdateError) {
            return errorResponse(`Failed to update location: ${locUpdateError.message}`, 500);
          }
        }
      }
    }

    // Handle location_id change
    if (body.location_id !== undefined) {
      const newLocationId = body.location_id as string | null;
      if (newLocationId !== null) {
        // Verify location belongs to the same partner
        const { data: loc, error: locError } = await supabase
          .from("locations")
          .select("id, partner_id")
          .eq("id", newLocationId)
          .maybeSingle();

        if (locError) return errorResponse("Failed to verify location", 500);
        if (!loc) return errorResponse("Location not found", 404);
        if (loc.partner_id !== existingParty.partner_id) {
          return errorResponse("Forbidden: location belongs to another partner", 403);
        }
      }

      const { error: locIdError } = await supabase
        .from("parties")
        .update({ location_id: newLocationId })
        .eq("id", partyId);

      if (locIdError) {
        return errorResponse(`Failed to update party location: ${locIdError.message}`, 500);
      }
    }

    if (Object.keys(partyUpdates).length === 0 && !locationData && body.location_id === undefined) {
      return errorResponse("No fields to update", 400);
    }

    return successResponse({ success: true });
  }

  // ─── update_status ───
  if (action === "update_status") {
    const partyId = body.party_id;
    if (typeof partyId !== "string" || !partyId) {
      return errorResponse("Missing party_id", 400);
    }

    const status = body.status;
    if (typeof status !== "string" || !VALID_STATUSES.includes(status)) {
      return errorResponse(`Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`, 400);
    }

    // Fetch party to verify ownership
    const { data: existingParty, error: fetchError } = await supabase
      .from("parties")
      .select("id, partner_id")
      .eq("id", partyId)
      .maybeSingle();

    if (fetchError) return errorResponse("Failed to load party", 500);
    if (!existingParty) return errorResponse("Party not found", 404);

    // Check partner permission
    const permCheck = await checkPartnerPermission(supabase, existingParty.partner_id, userId);
    if (permCheck instanceof Response) return permCheck;

    const { error: updateError } = await supabase
      .from("parties")
      .update({ status })
      .eq("id", partyId);

    if (updateError) {
      return errorResponse(`Failed to update party status: ${updateError.message}`, 500);
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
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

  const hasPermission = (perm?.permissions as string[] | null)?.includes("PARTY_MANAGE") ?? false;
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }
}

function validateEntryGroupTemplates(templates: unknown[]): Response | null {
  for (let i = 0; i < templates.length; i++) {
    const t = templates[i] as Record<string, unknown>;
    if (typeof t !== "object" || t === null || Array.isArray(t)) {
      return errorResponse(`entry_group_templates[${i}] must be an object`, 400);
    }
    if (t.gender !== undefined && t.gender !== null) {
      if (typeof t.gender !== "string" || !VALID_GENDERS.includes(t.gender)) {
        return errorResponse(`entry_group_templates[${i}].gender must be one of: ${VALID_GENDERS.join(", ")}`, 400);
      }
    }
    if (t.birth_year_min !== undefined && t.birth_year_min !== null) {
      if (typeof t.birth_year_min !== "number" || t.birth_year_min < 1900 || t.birth_year_min > 2100) {
        return errorResponse(`entry_group_templates[${i}].birth_year_min must be a valid year`, 400);
      }
    }
    if (t.birth_year_max !== undefined && t.birth_year_max !== null) {
      if (typeof t.birth_year_max !== "number" || t.birth_year_max < 1900 || t.birth_year_max > 2100) {
        return errorResponse(`entry_group_templates[${i}].birth_year_max must be a valid year`, 400);
      }
    }
    if (t.birth_year_min !== undefined && t.birth_year_max !== undefined &&
        t.birth_year_min !== null && t.birth_year_max !== null) {
      if ((t.birth_year_min as number) > (t.birth_year_max as number)) {
        return errorResponse(`entry_group_templates[${i}].birth_year_min cannot exceed birth_year_max`, 400);
      }
    }
  }
  return null;
}

function validateTicketTemplates(templates: unknown[]): Response | null {
  for (let i = 0; i < templates.length; i++) {
    const t = templates[i] as Record<string, unknown>;
    if (typeof t !== "object" || t === null || Array.isArray(t)) {
      return errorResponse(`ticket_templates[${i}] must be an object`, 400);
    }
    if (typeof t.name !== "string" || !t.name.trim()) {
      return errorResponse(`ticket_templates[${i}].name is required`, 400);
    }
    if (typeof t.quantity !== "number" || t.quantity < 0) {
      return errorResponse(`ticket_templates[${i}].quantity must be a non-negative number`, 400);
    }
    if (t.price !== undefined && t.price !== null) {
      if (typeof t.price !== "number" || t.price < 0) {
        return errorResponse(`ticket_templates[${i}].price must be >= 0`, 400);
      }
    }
  }
  return null;
}
