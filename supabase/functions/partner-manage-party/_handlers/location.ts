import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { LOCATION_FIELDS } from "../_lib/constants.ts";

export async function handleCreateLocation(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const partnerId = body.partner_id;
  if (typeof partnerId !== "string" || !partnerId) {
    return errorResponse("Missing partner_id", 400);
  }

  const locationData = body.location;
  if (
    typeof locationData !== "object" || locationData === null ||
    Array.isArray(locationData)
  ) {
    return errorResponse("Missing or invalid location object", 400);
  }
  const location = locationData as Record<string, unknown>;

  if (typeof location.name !== "string" || !location.name.trim()) {
    return errorResponse("Missing location name", 400);
  }
  if (typeof location.address !== "string" || !location.address.trim()) {
    return errorResponse("Missing location address", 400);
  }

  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    [
      "PARTY_MANAGE",
    ],
  );
  if (permCheck) return permCheck;

  const record: Record<string, unknown> = { partner_id: partnerId };
  for (const field of LOCATION_FIELDS) {
    if (location[field] !== undefined) record[field] = location[field];
  }

  const { data, error } = await supabase
    .from("locations")
    .insert(record)
    .select("id")
    .single();

  if (error) {
    return errorResponse(`Failed to create location: ${error.message}`, 500);
  }

  return successResponse({ success: true, location_id: data.id });
}

export async function handleUpdateLocation(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const locationId = body.location_id;
  if (typeof locationId !== "string" || !locationId) {
    return errorResponse("Missing location_id", 400);
  }

  const locationData = body.location;
  if (
    typeof locationData !== "object" || locationData === null ||
    Array.isArray(locationData)
  ) {
    return errorResponse("Missing or invalid location object", 400);
  }
  const location = locationData as Record<string, unknown>;

  const { data: existing, error: fetchError } = await supabase
    .from("locations")
    .select("id, partner_id")
    .eq("id", locationId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load location", 500);
  if (!existing) return errorResponse("Location not found", 404);

  const permCheck = await requirePartnerPermission(
    supabase,
    existing.partner_id,
    userId,
    ["PARTY_MANAGE"],
  );
  if (permCheck) return permCheck;

  const updates: Record<string, unknown> = {};
  for (const field of LOCATION_FIELDS) {
    if (location[field] !== undefined) updates[field] = location[field];
  }

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update", 400);
  }

  const { error: updateError } = await supabase
    .from("locations")
    .update(updates)
    .eq("id", locationId);

  if (updateError) {
    return errorResponse(
      `Failed to update location: ${updateError.message}`,
      500,
    );
  }

  return successResponse({ success: true });
}
