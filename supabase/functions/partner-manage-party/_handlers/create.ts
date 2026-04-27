import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { LOCATION_FIELDS, PARTY_FIELDS, VALID_STATUSES } from "../_lib/constants.ts";
import {
  validateEntryGroupTemplates,
  validateTicketTemplates,
} from "../_lib/validators.ts";

export async function handleCreate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  // Require partner_id from client (supports multi-partner users)
  const partnerId = body.partner_id;
  if (typeof partnerId !== "string" || !partnerId) {
    return errorResponse("Missing partner_id", 400);
  }

  // Validate party fields
  const partyData = body.party;
  if (
    typeof partyData !== "object" || partyData === null ||
    Array.isArray(partyData)
  ) {
    return errorResponse("Missing or invalid party object", 400);
  }
  const party = partyData as Record<string, unknown>;

  if (typeof party.title !== "string" || !party.title.trim()) {
    return errorResponse("Missing party title", 400);
  }

  // Check partner permission
  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["PARTY_MANAGE"]);
  if (permCheck) return permCheck;

  // ── Pre-validate all payloads before any DB writes ──

  // Validate status if provided
  if (party.status !== undefined) {
    if (
      typeof party.status !== "string" ||
      !VALID_STATUSES.includes(party.status as typeof VALID_STATUSES[number])
    ) {
      return errorResponse(
        `Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`,
        400,
      );
    }
  }

  // Validate location input if new location
  let newLocationInput: Record<string, unknown> | null = null;
  const existingLocationId = body.location_id;
  if (
    body.location && typeof body.location === "object" &&
    !Array.isArray(body.location)
  ) {
    newLocationInput = body.location as Record<string, unknown>;
    if (
      typeof newLocationInput.name !== "string" ||
      !newLocationInput.name.trim()
    ) {
      return errorResponse("Missing location name", 400);
    }
    if (
      typeof newLocationInput.address !== "string" ||
      !newLocationInput.address.trim()
    ) {
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
    const UUID_RE =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
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
      if (tagCheckError) {
        return errorResponse("Failed to validate tag IDs", 500);
      }
      if (
        !existingTags || existingTags.length !== (tagIds as string[]).length
      ) {
        return errorResponse("One or more tag_ids do not exist", 400);
      }
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
      return errorResponse(
        "Forbidden: location belongs to another partner",
        403,
      );
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
      return errorResponse(
        `Failed to create location: ${locInsertError.message}`,
        500,
      );
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
  if (!rpcData) {
    return errorResponse("Failed to create party: no party_id returned", 500);
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
      return errorResponse(
        `Failed to create entry group templates: ${egtError.message}`,
        500,
      );
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
      return errorResponse(
        `Failed to create ticket templates: ${ttError.message}`,
        500,
      );
    }
  }

  return successResponse({ success: true, party_id: partyId });
}
