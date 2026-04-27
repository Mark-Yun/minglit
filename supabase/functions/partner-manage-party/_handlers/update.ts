import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { LOCATION_FIELDS, PARTY_FIELDS, VALID_STATUSES } from "../_lib/constants.ts";
import { validateEntryGroupTemplates } from "../_lib/validators.ts";

export async function handleUpdate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
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
  const permCheck = await requirePartnerPermission(
    supabase,
    existingParty.partner_id,
    userId,
    ["PARTY_MANAGE"],
  );
  if (permCheck) return permCheck;

  // ── Pre-validate all payloads before any DB writes ──

  // Build party updates
  const partyData = body.party;
  const partyUpdates: Record<string, unknown> = {};
  if (
    typeof partyData === "object" && partyData !== null &&
    !Array.isArray(partyData)
  ) {
    const party = partyData as Record<string, unknown>;
    for (const field of PARTY_FIELDS) {
      if (party[field] !== undefined) {
        partyUpdates[field] = party[field];
      }
    }

    // Validate status if provided
    if (partyUpdates.status !== undefined) {
      if (
        typeof partyUpdates.status !== "string" ||
        !VALID_STATUSES.includes(partyUpdates.status as typeof VALID_STATUSES[number])
      ) {
        return errorResponse(
          `Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`,
          400,
        );
      }
    }
  }

  // Validate tag_ids before any DB writes
  // Fix #1136: tag_ids 검증을 모든 write 전으로 이동 — 부분 업데이트 방지
  const rawUpdateTagIds = body.tag_ids;
  // Fix #1182: deduplicate tag_ids before validation (#13)
  const updateTagIds =
    rawUpdateTagIds !== undefined && Array.isArray(rawUpdateTagIds)
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
    const UUID_RE =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
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
      if (
        !existingTags ||
        existingTags.length !== (updateTagIds as string[]).length
      ) {
        return errorResponse("One or more tag_ids do not exist", 400);
      }
    }
  }

  // Fix #1733: entry_group_templates 업데이트 검증 (write 전 사전 검증)
  const updateEntryGroupTemplates = body.entry_group_templates;
  if (updateEntryGroupTemplates !== undefined) {
    if (!Array.isArray(updateEntryGroupTemplates)) {
      return errorResponse("entry_group_templates must be an array", 400);
    }
    const egtValidationError = validateEntryGroupTemplates(
      updateEntryGroupTemplates,
    );
    if (egtValidationError) return egtValidationError;
  }

  if (
    Object.keys(partyUpdates).length === 0 &&
    !body.location &&
    body.location_id === undefined &&
    updateTagIds === undefined &&
    updateEntryGroupTemplates === undefined
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
      return errorResponse(
        `Failed to update party: ${updateError.message}`,
        500,
      );
    }
  }

  // Update location if provided
  const locationData = body.location;
  if (
    typeof locationData === "object" && locationData !== null &&
    !Array.isArray(locationData)
  ) {
    const locInput = locationData as Record<string, unknown>;

    // Check if party has a location_id to update
    const { data: partyWithLoc, error: locFetchError } = await supabase
      .from("parties")
      .select("location_id")
      .eq("id", partyId)
      .single();

    if (locFetchError) {
      return errorResponse("Failed to fetch party location", 500);
    }

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
          return errorResponse(
            `Failed to update location: ${locUpdateError.message}`,
            500,
          );
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
        return errorResponse(
          "Forbidden: location belongs to another partner",
          403,
        );
      }
    }

    const { error: locIdError } = await supabase
      .from("parties")
      .update({ location_id: newLocationId })
      .eq("id", partyId);

    if (locIdError) {
      return errorResponse(
        `Failed to update party location: ${locIdError.message}`,
        500,
      );
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
      return errorResponse(
        `Failed to update party tags: ${ptRpcError.message}`,
        500,
      );
    }
  }

  // Fix #1733: UPSERT + selective DELETE — 기존 ID 보존으로 ticket_templates 링크 유지
  if (updateEntryGroupTemplates !== undefined) {
    const templates = updateEntryGroupTemplates as Record<string, unknown>[];

    const { data: existing, error: fetchExistingError } = await supabase
      .from("entry_group_templates")
      .select("id")
      .eq("party_id", partyId);
    if (fetchExistingError) {
      return errorResponse(
        `Failed to fetch existing entry group templates: ${fetchExistingError.message}`,
        500,
      );
    }

    const existingIds = (existing ?? []).map((r: { id: string }) =>
      r.id as string
    );
    const incomingWithId = templates.filter((t) =>
      typeof t.id === "string" && (t.id as string).length > 0
    );
    const incomingWithoutId = templates.filter((t) =>
      !t.id || (t.id as string).length === 0
    );
    const keptIds = incomingWithId.map((t) => t.id as string);
    const toDeleteIds = existingIds.filter((id: string) =>
      !keptIds.includes(id)
    );

    if (toDeleteIds.length > 0) {
      const { data: affectedTickets, error: fetchTicketsError } =
        await supabase
          .from("ticket_templates")
          .select("id, target_entry_group_ids")
          .eq("party_id", partyId);
      if (fetchTicketsError) {
        return errorResponse(
          `Failed to fetch ticket templates: ${fetchTicketsError.message}`,
          500,
        );
      }

      for (const ticket of (affectedTickets ?? [])) {
        const tt = ticket as { id: string; target_entry_group_ids: string[] };
        const hadAny = toDeleteIds.some((d) =>
          tt.target_entry_group_ids?.includes(d)
        );
        if (hadAny) {
          const updatedIds = (tt.target_entry_group_ids ?? []).filter((
            id: string,
          ) => !toDeleteIds.includes(id));
          const { error: ttUpdateError } = await supabase
            .from("ticket_templates")
            .update({ target_entry_group_ids: updatedIds })
            .eq("id", tt.id);
          if (ttUpdateError) {
            return errorResponse(
              `Failed to update ticket template references: ${ttUpdateError.message}`,
              500,
            );
          }
        }
      }

      const { error: deleteEgtError } = await supabase
        .from("entry_group_templates")
        .delete()
        .in("id", toDeleteIds);
      if (deleteEgtError) {
        return errorResponse(
          `Failed to delete entry group templates: ${deleteEgtError.message}`,
          500,
        );
      }
    }

    for (const t of incomingWithId) {
      const { error: updateEgtError } = await supabase
        .from("entry_group_templates")
        .update({
          label: t.label ?? null,
          gender: t.gender ?? null,
          birth_year_min: t.birth_year_min ?? null,
          birth_year_max: t.birth_year_max ?? null,
          required_verification_ids: t.required_verification_ids ?? [],
        })
        .eq("id", t.id as string)
        .eq("party_id", partyId);
      if (updateEgtError) {
        return errorResponse(
          `Failed to update entry group template: ${updateEgtError.message}`,
          500,
        );
      }
    }

    if (incomingWithoutId.length > 0) {
      const newTemplates = incomingWithoutId.map((t) => ({
        party_id: partyId,
        label: t.label ?? null,
        gender: t.gender ?? null,
        birth_year_min: t.birth_year_min ?? null,
        birth_year_max: t.birth_year_max ?? null,
        required_verification_ids: t.required_verification_ids ?? [],
      }));
      const { error: insertEgtError } = await supabase
        .from("entry_group_templates")
        .insert(newTemplates);
      if (insertEgtError) {
        return errorResponse(
          `Failed to insert new entry group templates: ${insertEgtError.message}`,
          500,
        );
      }
    }
  }

  return successResponse({ success: true });
}
