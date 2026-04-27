import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { VALID_STATUSES } from "../_lib/constants.ts";

export async function handleUpdateStatus(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const partyId = body.party_id;
  if (typeof partyId !== "string" || !partyId) {
    return errorResponse("Missing party_id", 400);
  }

  const status = body.status;
  if (typeof status !== "string" || !VALID_STATUSES.includes(status as typeof VALID_STATUSES[number])) {
    return errorResponse(
      `Invalid status. Must be one of: ${VALID_STATUSES.join(", ")}`,
      400,
    );
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

  const { error: updateError } = await supabase
    .from("parties")
    .update({ status })
    .eq("id", partyId);

  if (updateError) {
    return errorResponse(
      `Failed to update party status: ${updateError.message}`,
      500,
    );
  }

  return successResponse({ success: true });
}
