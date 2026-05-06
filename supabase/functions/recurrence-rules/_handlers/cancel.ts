import type { SupabaseClient } from "@supabase/supabase-js";
import {
  errorResponse,
  successResponse,
} from "../../_shared/response_utils.ts";
import { requirePartnerPermission } from "../../_shared/partner_permissions.ts";

export async function handleCancel(
  body: Record<string, unknown>,
  supabase: SupabaseClient,
  userId: string,
): Promise<Response> {
  const ruleId = body.rule_id;
  if (typeof ruleId !== "string" || !ruleId) {
    return errorResponse("Missing rule_id", 400);
  }

  const { data: rule, error: fetchError } = await supabase
    .from("recurrence_rules")
    .select("id, status, parties!inner(partner_id)")
    .eq("id", ruleId)
    .maybeSingle();

  if (fetchError) return errorResponse("Failed to load recurrence rule", 500);
  if (!rule) return errorResponse("Recurrence rule not found", 404);

  if (rule.status === "cancelled") {
    return errorResponse("Rule is already cancelled", 400);
  }

  const partnerId = (rule.parties as unknown as Record<string, unknown>).partner_id as string;
  const permCheck = await requirePartnerPermission(supabase, partnerId, userId, ["PARTY_MANAGE"]);
  if (permCheck) return permCheck;

  const { error: updateError } = await supabase
    .from("recurrence_rules")
    .update({ status: "cancelled" })
    .eq("id", ruleId);

  if (updateError) {
    return errorResponse(`Failed to cancel rule: ${updateError.message}`, 500);
  }

  return successResponse({ success: true });
}
