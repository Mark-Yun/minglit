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

    // Validate tag_ids if provided (must validate before any DB write)
    // Fix #1136: tag_ids 검증을 party INSERT 전으로 이동 — 잘못된 입력 시 고아 row 방지
    const rawTagIds = body.tag_ids;
    // Fix #1182: deduplicate tag_ids before validation (#13)
    const tagIds = rawTagIds !== undefined && Array.isArray(rawTagIds)
      ? [...new Set(rawTagIds as string[])]
      : rawTagIds;
    if (tagIds !== undefined) {
      if (!Array.isArray(tagIds)) {
        return errorResponse("tag_ids must be an array", 400);
      }
      if (tagIds.length > 5) {
        return errorResponse("tag_ids must contain at most 5 tags", 400);
      }
      // Fix #1182: UUID format validation (#12)
      const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      for (let i = 0; i < tagIds.length; i++) {
        if (!UUID_RE.test(tagIds[i])) {
          return errorResponse(`tag_ids[${i}] must be a valid UUID`, 400);
        }
      }
      // Fix #1136: validate tag IDs exist before party creation
      // Prevents orphaned party rows when FK constraint would fail during party_tags INSERT
      if (tagIds.length > 0) {
        const { data: existingTags, error: tagCheckError } = await supabase
          .from("tags")
          .select("id")
          .in("id", tagIds as string[]);
        if (tagCheckError) return errorResponse("Failed to validate tag IDs", 500);
        if (!existingTags || existingTags.length !== (tagIds as string[]).length)
          return errorResponse("One or more tag_ids do not exist", 400);
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

    // Fix #1223: parties INSERT + party_tags INSERT を RPC로 원자적 처리
    // 기존 2단계 write(INSERT parties → INSERT party_tags) 는 2단계 실패 시 고아 row 발생.
    // create_party_with_tags RPC 가 단일 트랜잭션으로 두 write를 묶어 처리한다.
    const { data: rpcData, error: rpcError } = await supabase
      .rpc("create_party_with_tags", {
        p_party: partyRecord,
        p_tag_ids: Array.isArray(tagIds) ? tagIds as string[] : [],
      });

    if (rpcError) {
      return errorResponse(`Failed to create party: ${rpcError.message}`, 500);
    }

    const partyId = rpcData as string;

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

    // ── Pre-validate all payloads before any DB writes ──

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

    // Validate tag_ids before any DB writes
    // Fix #1136: tag_ids 검증을 모든 write 전으로 이동 — 부분 업데이트 방지
    const rawUpdateTagIds = body.tag_ids;
    // Fix #1182: deduplicate tag_ids before validation (#13)
    const updateTagIds = rawUpdateTagIds !== undefined && Array.isArray(rawUpdateTagIds)
      ? [...new Set(rawUpdateTagIds as string[])]
      : rawUpdateTagIds;
    if (updateTagIds !== undefined) {
      if (!Array.isArray(updateTagIds)) {
        return errorResponse("tag_ids must be an array", 400);
      }
      if (updateTagIds.length > 5) {
        return errorResponse("tag_ids must contain at most 5 tags", 400);
      }
      // Fix #1182: UUID format validation (#12)
      const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      for (let i = 0; i < updateTagIds.length; i++) {
        if (!UUID_RE.test(updateTagIds[i])) {
          return errorResponse(`tag_ids[${i}] must be a valid UUID`, 400);
        }
      }
      // Validate tag IDs exist in the database — prevents partial writes
      // if FK constraint would fail during the INSERT phase
      if (updateTagIds.length > 0) {
        const { data: existingTags, error: tagCheckError } = await supabase
          .from("tags")
          .select("id")
          .in("id", updateTagIds as string[]);
        if (tagCheckError) {
          return errorResponse("Failed to validate tag IDs", 500);
        }
        if (!existingTags || existingTags.length !== (updateTagIds as string[]).length) {
          return errorResponse("One or more tag_ids do not exist", 400);
        }
      }
    }

    if (
      Object.keys(partyUpdates).length === 0 &&
      !body.location &&
      body.location_id === undefined &&
      updateTagIds === undefined
    ) {
      return errorResponse("No fields to update", 400);
    }

    // ── All validations passed — now perform DB writes ──

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

    // Update party_tags if tag_ids present in body (undefined = no change, [] = clear all)
    // Fix #1223: 2단계 DELETE+UPSERT 를 RPC로 원자적 처리
    // update_party_tags RPC 가 단일 트랜잭션으로 DELETE stale rows → INSERT new rows 처리.
    // Fix #1149 패턴(DELETE-first)도 RPC 내부에서 동일하게 유지됨.
    if (updateTagIds !== undefined) {
      const { error: ptRpcError } = await supabase
        .rpc("update_party_tags", {
          p_party_id: partyId,
          p_tag_ids: updateTagIds as string[],
        });
      if (ptRpcError) {
        return errorResponse(`Failed to update party tags: ${ptRpcError.message}`, 500);
      }
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
