import type { SupabaseClient } from "@supabase/supabase-js";
import { requirePartnerPermission } from "../_shared/partner_permissions.ts";
import {
  isApplicationApprovableForPartnerApproval,
  mapBulkApprovalRpcResult,
  mapSingleApprovalRpcResult,
} from "../_shared/domains/event/application_approval_policy.ts";
import type { PartnerApproveInput } from "./input.ts";

export type PartnerApproveServiceResult =
  | { ok: true; type: "approve"; approved: 1; applicationId: string }
  | {
    ok: true;
    type: "bulk_approve";
    approved: number;
    eventId: string;
    skippedDueToCapacity: number;
    remainingSlotsBeforeApproval: number;
  }
  | { ok: false; status: number; message: string; details?: unknown };

export function approveApplication(args: {
  supabase: SupabaseClient;
  input: PartnerApproveInput;
  userId: string;
}): Promise<PartnerApproveServiceResult | Response> {
  if (args.input.action === "approve") {
    return approveSingle(args.supabase, args.input.applicationId, args.userId);
  }
  return approveBulk(args.supabase, args.input.eventId, args.userId);
}

async function approveSingle(
  supabase: SupabaseClient,
  applicationId: string,
  userId: string,
): Promise<PartnerApproveServiceResult | Response> {
  const { data: app, error: fetchError } = await supabase
    .from("event_applications")
    .select(
      "id, status, event_id, events!inner(party_id, parties!inner(partner_id))",
    )
    .eq("id", applicationId)
    .maybeSingle();

  if (fetchError) return fail(500, "Failed to load application");
  if (!app) return fail(404, "Application not found");

  const partnerId = extractApplicationPartnerId(app as Record<string, unknown>);
  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    [
      "EVENT_MANAGE",
      "APPLICATION_MANAGE",
    ],
  );
  if (permCheck) return permCheck;

  const status = String((app as { status?: unknown }).status);
  if (!isApplicationApprovableForPartnerApproval(status)) {
    return fail(400, `Cannot approve application with status '${status}'`);
  }

  const { data: approvalResult, error: approvalError } = await supabase
    .rpc("approve_event_application_with_capacity_guard", {
      p_application_id: applicationId,
    });

  if (approvalError) return fail(500, "Failed to approve application");

  const mapped = mapSingleApprovalRpcResult(approvalResult);
  if (!mapped.ok) return fail(mapped.status, mapped.message, mapped.details);
  return { ok: true, type: "approve", approved: 1, applicationId };
}

async function approveBulk(
  supabase: SupabaseClient,
  eventId: string,
  userId: string,
): Promise<PartnerApproveServiceResult | Response> {
  const { data: event, error: eventError } = await supabase
    .from("events")
    .select("id, party_id, parties!inner(partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (eventError) return fail(500, "Failed to load event");
  if (!event) return fail(404, "Event not found");

  const partnerId = extractEventPartnerId(event as Record<string, unknown>);
  const permCheck = await requirePartnerPermission(
    supabase,
    partnerId,
    userId,
    [
      "EVENT_MANAGE",
      "APPLICATION_MANAGE",
    ],
  );
  if (permCheck) return permCheck;

  const { data: bulkApprovalResult, error: bulkApprovalError } = await supabase
    .rpc("bulk_approve_event_applications_with_capacity_guard", {
      p_event_id: eventId,
    });

  if (bulkApprovalError) return fail(500, "Failed to bulk approve");

  const mapped = mapBulkApprovalRpcResult(bulkApprovalResult);
  if (!mapped.ok) return fail(mapped.status, mapped.message, mapped.details);
  return {
    ok: true,
    type: "bulk_approve",
    approved: mapped.approved,
    eventId,
    skippedDueToCapacity: mapped.skippedDueToCapacity,
    remainingSlotsBeforeApproval: mapped.remainingSlotsBeforeApproval,
  };
}

function extractApplicationPartnerId(app: Record<string, unknown>): string {
  const event = app.events as Record<string, unknown>;
  return extractEventPartnerId(event);
}

function extractEventPartnerId(event: Record<string, unknown>): string {
  const party = event.parties as Record<string, unknown>;
  return party.partner_id as string;
}

function fail(
  status: number,
  message: string,
  details?: unknown,
): Extract<PartnerApproveServiceResult, { ok: false }> {
  if (details === undefined) return { ok: false, status, message };
  return { ok: false, status, message, details };
}
