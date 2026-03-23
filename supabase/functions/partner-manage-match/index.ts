// partner-manage-match — Manage match rules for events (set_rules, clear_rules)
// Issue #305: RLS write strategy 전환 + vote_count 지원

import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

interface RuleInput {
  source_group_id: string;
  target_group_id: string;
  vote_count?: number;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (req.method !== "POST") return errorResponse("Method not allowed", 405);

  // 1. Environment check (before auth — requireAuth also reads these)

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

  const eventId = body.event_id;
  if (typeof eventId !== "string" || !eventId) return errorResponse("Missing event_id", 400);

  // 4. Supabase client (service role)
  const supabase = createServiceClient();

  // 5. Verify ownership: event → party → partner
  const { data: event, error: eventError } = await supabase
    .from("events")
    .select("id, status, party:party_id(id, partner_id)")
    .eq("id", eventId)
    .maybeSingle();

  if (eventError) {
    return errorResponse("Failed to load event", 500);
  }
  if (!event) {
    return errorResponse("Event not found", 404);
  }

  const party = event.party as { id: string; partner_id: string } | null;
  if (!party) {
    return errorResponse("Event has no associated party", 404);
  }

  // Check partner permission (service_role bypasses RLS, query directly)
  const { data: perm, error: permError } = await supabase
    .from("partner_member_permissions")
    .select("permissions")
    .eq("partner_id", party.partner_id)
    .eq("user_id", userId)
    .maybeSingle();

  if (permError) {
    return errorResponse("Failed to verify partner permissions", 500);
  }

  const hasPermission = (perm?.permissions as string[] | null)?.includes("PARTY_MANAGE") ?? false;
  if (!hasPermission) {
    return errorResponse("Forbidden: insufficient partner permissions", 403);
  }

  // Check event status — only 'scheduled' events can have rules modified
  if (event.status !== "scheduled") {
    return errorResponse(
      `Cannot modify match rules for event with status '${event.status}'`,
      400,
    );
  }

  // ─── set_rules ───
  if (action === "set_rules") {
    const rules = body.rules as RuleInput[] | undefined;
    if (!Array.isArray(rules)) {
      return errorResponse("Missing or invalid rules array", 400);
    }

    // Validate each rule
    for (const rule of rules) {
      if (!rule.source_group_id || !rule.target_group_id) {
        return errorResponse("Each rule must have source_group_id and target_group_id", 400);
      }
      if (rule.source_group_id === rule.target_group_id) {
        return errorResponse("source_group_id and target_group_id must be different", 400);
      }
      const voteCount = rule.vote_count ?? 1;
      if (!Number.isInteger(voteCount) || voteCount < 1) {
        return errorResponse("vote_count must be a positive integer", 400);
      }
    }

    // Validate all group IDs belong to this event
    if (rules.length > 0) {
      const allGroupIds = [
        ...new Set(rules.flatMap((r) => [r.source_group_id, r.target_group_id])),
      ];

      const { data: groups, error: groupsError } = await supabase
        .from("entry_groups")
        .select("id")
        .eq("event_id", eventId)
        .in("id", allGroupIds);

      if (groupsError) {
        return errorResponse("Failed to verify entry groups", 500);
      }

      const validGroupIds = new Set((groups ?? []).map((g: { id: string }) => g.id));
      const invalidIds = allGroupIds.filter((id) => !validGroupIds.has(id));
      if (invalidIds.length > 0) {
        return errorResponse(
          `Invalid group IDs for this event: ${invalidIds.join(", ")}`,
          400,
        );
      }
    }

    // Atomic replace via RPC (advisory lock + delete + insert in one transaction)
    const records = rules.map((r) => ({
      source_group_id: r.source_group_id,
      target_group_id: r.target_group_id,
      vote_count: r.vote_count ?? 1,
    }));

    const { error: replaceError } = await supabase.rpc("replace_match_rules", {
      p_event_id: eventId,
      p_rules: records,
    });

    if (replaceError) {
      return errorResponse(`Failed to replace rules: ${replaceError.message}`, 500);
    }

    return successResponse({ success: true, count: rules.length });
  }

  // ─── clear_rules ───
  if (action === "clear_rules") {
    // Reuse RPC with empty rules for atomic clear
    const { error: clearError } = await supabase.rpc("replace_match_rules", {
      p_event_id: eventId,
      p_rules: [],
    });

    if (clearError) {
      return errorResponse("Failed to clear rules", 500);
    }

    return successResponse({ success: true });
  }

  return errorResponse(`Unknown action: ${action}`, 400);
});
