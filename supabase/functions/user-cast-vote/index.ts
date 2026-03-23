// user-cast-vote — Cast a matching vote for a candidate in an event
// Replaces direct client writes to match_votes (RLS write → EF)

import { createClient } from "@supabase/supabase-js";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { requireAuth } from "../_shared/auth_utils.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const voterId = auth;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Missing server configuration", 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const eventId = body.event_id as string | undefined;
  const candidateId = body.candidate_id as string | undefined;

  if (!eventId) return errorResponse("Missing event_id", 400);
  if (!candidateId) return errorResponse("Missing candidate_id", 400);
  if (candidateId === voterId) return errorResponse("자기 자신에게 투표할 수 없습니다", 400);

  // 1. Fetch event with vote period + end_time fallback
  const { data: event, error: eventError } = await supabase
    .from("events")
    .select("id, status, vote_start_at, vote_end_at, end_time")
    .eq("id", eventId)
    .maybeSingle();

  if (eventError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  // 2. Vote period validation
  if (!event.vote_start_at) {
    return errorResponse("투표 기능이 활성화되지 않았습니다", 400);
  }

  const now = new Date();
  if (now < new Date(event.vote_start_at)) {
    return errorResponse("투표가 아직 시작되지 않았습니다", 400);
  }
  // Fix #306: vote_end_at이 없으면 end_time을 fallback deadline으로 사용
  const deadline = event.vote_end_at ?? event.end_time;
  if (deadline && now > new Date(deadline)) {
    return errorResponse("투표가 마감되었습니다", 400);
  }

  // 3. Verify voter is checked_in participant
  const { data: voterParticipant, error: voterError } = await supabase
    .from("event_participants")
    .select("status, ticket_id")
    .eq("event_id", eventId)
    .eq("user_id", voterId)
    .maybeSingle();

  if (voterError) return errorResponse("Failed to verify participant", 500);
  if (!voterParticipant) return errorResponse("이벤트 참가자가 아닙니다", 400);
  if (voterParticipant.status !== "checked_in") {
    return errorResponse("체크인 후 투표 가능합니다", 400);
  }

  // 4. Verify candidate is checked_in participant
  const { data: candidateParticipant, error: candidateError } = await supabase
    .from("event_participants")
    .select("status, ticket_id")
    .eq("event_id", eventId)
    .eq("user_id", candidateId)
    .maybeSingle();

  if (candidateError) return errorResponse("Failed to verify candidate", 500);
  if (!candidateParticipant) return errorResponse("후보자가 이벤트 참가자가 아닙니다", 400);
  if (candidateParticipant.status !== "checked_in") {
    return errorResponse("후보자가 체크인하지 않았습니다", 400);
  }

  // 5. Fetch voter's group from ticket → target_entry_group_ids (fail-closed)
  const { data: voterTicket, error: voterTicketError } = await supabase
    .from("tickets")
    .select("target_entry_group_ids")
    .eq("id", voterParticipant.ticket_id)
    .maybeSingle();

  if (voterTicketError) return errorResponse("Failed to load voter ticket", 500);

  const { data: candidateTicket, error: candidateTicketError } = await supabase
    .from("tickets")
    .select("target_entry_group_ids")
    .eq("id", candidateParticipant.ticket_id)
    .maybeSingle();

  if (candidateTicketError) return errorResponse("Failed to load candidate ticket", 500);

  const voterGroupIds: string[] = voterTicket?.target_entry_group_ids ?? [];
  const candidateGroupIds: string[] = candidateTicket?.target_entry_group_ids ?? [];

  // Fix #306: 그룹 정보가 없으면 거부 (fail-closed)
  if (voterGroupIds.length === 0 || candidateGroupIds.length === 0) {
    return errorResponse("그룹 정보를 확인할 수 없습니다", 400);
  }

  // 6. Check match_rules: voter's group → candidate's group allowed?
  const { data: rules, error: rulesError } = await supabase
    .from("match_rules")
    .select("vote_count")
    .eq("event_id", eventId)
    .in("source_group_id", voterGroupIds)
    .in("target_group_id", candidateGroupIds);

  if (rulesError) return errorResponse("Failed to load match rules", 500);
  if (!rules || rules.length === 0) {
    return errorResponse("매칭 대상이 아닙니다", 400);
  }

  // 7. Atomic vote count check + insert via RPC (prevents race condition)
  const maxVoteCount = Math.max(...rules.map((r: { vote_count: number }) => r.vote_count));

  const { data: rpcResult, error: rpcError } = await supabase.rpc("cast_match_vote", {
    p_event_id: eventId,
    p_voter_id: voterId,
    p_candidate_id: candidateId,
    p_max_vote_count: maxVoteCount,
  });

  if (rpcError) {
    if (rpcError.message?.includes("투표 수를 초과했습니다")) {
      return errorResponse("투표 수를 초과했습니다", 400);
    }
    if (rpcError.message?.includes("이미 투표한 후보입니다")) {
      return errorResponse("이미 투표한 후보입니다", 400);
    }
    if (rpcError.code === "23505") {
      return errorResponse("이미 투표한 후보입니다", 400);
    }
    if (rpcError.code === "23514") {
      return errorResponse("자기 자신에게 투표할 수 없습니다", 400);
    }
    return errorResponse(rpcError.message, 500);
  }

  return successResponse({ success: true });
});
