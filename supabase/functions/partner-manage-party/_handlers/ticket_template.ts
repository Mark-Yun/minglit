import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";
import { validateTicketTemplates } from "../_lib/validators.ts";

const TICKET_TEMPLATE_FIELDS = [
  "name",
  "description",
  "price",
  "quantity",
  "target_entry_group_ids",
  "required_verification_ids",
] as const;

export async function handleCreateTicketTemplate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const templateData = body.ticket_template;
  if (
    typeof templateData !== "object" || templateData === null ||
    Array.isArray(templateData)
  ) {
    return errorResponse("Missing or invalid ticket_template object", 400);
  }
  const template = templateData as Record<string, unknown>;

  const partyId = template.party_id;
  if (typeof partyId !== "string" || !partyId) {
    return errorResponse("Missing ticket_template.party_id", 400);
  }

  const partyCheck = await verifyPartyPermission(supabase, partyId, userId);
  if (partyCheck instanceof Response) return partyCheck;

  const validationError = validateTicketTemplates([template]);
  if (validationError) return validationError;

  const record = buildTicketTemplateRecord(template, partyId);
  const { data, error } = await supabase
    .from("ticket_templates")
    .insert(record)
    .select("id")
    .single();

  if (error) {
    return errorResponse(
      `Failed to create ticket template: ${error.message}`,
      500,
    );
  }

  return successResponse({ success: true, ticket_template_id: data.id });
}

export async function handleUpdateTicketTemplate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const templateId = body.ticket_template_id;
  if (typeof templateId !== "string" || !templateId) {
    return errorResponse("Missing ticket_template_id", 400);
  }

  const templateData = body.ticket_template;
  if (
    typeof templateData !== "object" || templateData === null ||
    Array.isArray(templateData)
  ) {
    return errorResponse("Missing or invalid ticket_template object", 400);
  }
  const template = templateData as Record<string, unknown>;

  const { data: existing, error: fetchError } = await supabase
    .from("ticket_templates")
    .select("id, party_id")
    .eq("id", templateId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load ticket template", 500);
  if (!existing) return errorResponse("Ticket template not found", 404);

  const partyCheck = await verifyPartyPermission(
    supabase,
    existing.party_id,
    userId,
  );
  if (partyCheck instanceof Response) return partyCheck;

  const validationError = validateTicketTemplates([{
    ...template,
    party_id: existing.party_id,
  }]);
  if (validationError) return validationError;

  const updates: Record<string, unknown> = {};
  for (const field of TICKET_TEMPLATE_FIELDS) {
    if (template[field] !== undefined) updates[field] = template[field];
  }

  if (Object.keys(updates).length === 0) {
    return errorResponse("No fields to update", 400);
  }

  const { error: updateError } = await supabase
    .from("ticket_templates")
    .update(updates)
    .eq("id", templateId);

  if (updateError) {
    return errorResponse(
      `Failed to update ticket template: ${updateError.message}`,
      500,
    );
  }

  return successResponse({ success: true });
}

export async function handleDeleteTicketTemplate(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const templateId = body.ticket_template_id;
  if (typeof templateId !== "string" || !templateId) {
    return errorResponse("Missing ticket_template_id", 400);
  }

  const { data: existing, error: fetchError } = await supabase
    .from("ticket_templates")
    .select("id, party_id")
    .eq("id", templateId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load ticket template", 500);
  if (!existing) return errorResponse("Ticket template not found", 404);

  const partyCheck = await verifyPartyPermission(
    supabase,
    existing.party_id,
    userId,
  );
  if (partyCheck instanceof Response) return partyCheck;

  const { error: deleteError } = await supabase
    .from("ticket_templates")
    .delete()
    .eq("id", templateId);

  if (deleteError) {
    return errorResponse(
      `Failed to delete ticket template: ${deleteError.message}`,
      500,
    );
  }

  return successResponse({ success: true });
}

async function verifyPartyPermission(
  supabase: SupabaseClient,
  partyId: string,
  userId: string,
): Promise<true | Response> {
  const { data: party, error } = await supabase
    .from("parties")
    .select("id, partner_id")
    .eq("id", partyId)
    .maybeSingle();

  if (error) return errorResponse("Failed to load party", 500);
  if (!party) return errorResponse("Party not found", 404);

  const permCheck = await requirePartnerPermission(
    supabase,
    party.partner_id,
    userId,
    ["PARTY_MANAGE"],
  );
  if (permCheck) return permCheck;
  return true;
}

function buildTicketTemplateRecord(
  template: Record<string, unknown>,
  partyId: string,
): Record<string, unknown> {
  const record: Record<string, unknown> = { party_id: partyId };
  for (const field of TICKET_TEMPLATE_FIELDS) {
    if (template[field] !== undefined) record[field] = template[field];
  }
  return record;
}
