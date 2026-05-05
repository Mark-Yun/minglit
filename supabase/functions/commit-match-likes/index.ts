import { requireAuth } from "../_shared/auth_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { createServiceClient } from "../_shared/supabase_client.ts";

initSentry();

const MAX_LIKES_PER_COMMIT = 3;

Deno.serve(withHandler(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();

  const auth = await requireAuth(req);
  if (auth instanceof Response) return auth;
  const voterId = auth;

  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const eventId = body.event_id as string | undefined;
  const candidateIds = body.candidate_ids as string[] | undefined;

  if (!eventId || typeof eventId !== "string") {
    return errorResponse("Missing or invalid event_id", 400);
  }
  if (
    !candidateIds ||
    !Array.isArray(candidateIds) ||
    !candidateIds.every((id) => typeof id === "string")
  ) {
    return errorResponse("Missing or invalid candidate_ids", 400);
  }

  const normalizedCandidateIds = [...new Set(candidateIds)];
  if (normalizedCandidateIds.length === 0) {
    return errorResponse("좋아요를 보낼 상대를 선택해 주세요", 400);
  }
  if (normalizedCandidateIds.length > MAX_LIKES_PER_COMMIT) {
    return errorResponse("좋아요는 최대 3명까지 보낼 수 있습니다", 400);
  }
  if (normalizedCandidateIds.includes(voterId)) {
    return errorResponse("자기 자신에게 좋아요를 보낼 수 없습니다", 400);
  }

  const supabase = createServiceClient();

  const { data: event, error: eventError } = await supabase
    .from("events")
    .select("id, status, vote_start_at, vote_end_at, end_time")
    .eq("id", eventId)
    .maybeSingle();

  if (eventError) return errorResponse("Failed to load event", 500);
  if (!event) return errorResponse("Event not found", 404);

  const now = new Date();
  const deadline = event.vote_end_at ?? event.end_time;
  const isMatchingWindow = event.status === "ongoing" &&
    event.vote_start_at &&
    now >= new Date(event.vote_start_at) &&
    (!deadline || now <= new Date(deadline));

  if (!isMatchingWindow) {
    return errorResponse(
      "매칭 선택 가능 시간이 아니에요",
      409,
      {
        code: "phase_mismatch",
        expected_phase: "matching",
        current_status: event.status,
        vote_start_at: event.vote_start_at,
        vote_end_at: deadline,
      },
    );
  }

  const { data: voterParticipant, error: voterError } = await supabase
    .from("event_participants")
    .select("status, ticket_id")
    .eq("event_id", eventId)
    .eq("user_id", voterId)
    .maybeSingle();

  if (voterError) return errorResponse("Failed to verify participant", 500);
  if (!voterParticipant) return errorResponse("이벤트 참가자가 아닙니다", 400);
  if (voterParticipant.status !== "checked_in") {
    return errorResponse("체크인 후 좋아요를 보낼 수 있습니다", 400);
  }

  const { data: candidateParticipants, error: candidateError } = await supabase
    .from("event_participants")
    .select("user_id, status, ticket_id")
    .eq("event_id", eventId)
    .in("user_id", normalizedCandidateIds);

  if (candidateError) return errorResponse("Failed to verify candidates", 500);

  const candidateParticipantRows = candidateParticipants ?? [];
  if (candidateParticipantRows.length !== normalizedCandidateIds.length) {
    return errorResponse("일부 후보를 찾을 수 없습니다", 400);
  }
  if (candidateParticipantRows.some((row) => row.status !== "checked_in")) {
    return errorResponse(
      "체크인한 참가자에게만 좋아요를 보낼 수 있습니다",
      400,
    );
  }

  const { data: voterTicket, error: voterTicketError } = await supabase
    .from("tickets")
    .select("target_entry_group_ids")
    .eq("id", voterParticipant.ticket_id)
    .maybeSingle();

  if (voterTicketError) {
    return errorResponse("Failed to load voter ticket", 500);
  }

  const voterGroupIds: string[] = voterTicket?.target_entry_group_ids ?? [];
  if (voterGroupIds.length === 0) {
    return errorResponse("그룹 정보를 확인할 수 없습니다", 400);
  }

  const ticketIds = candidateParticipantRows.map((row) =>
    row.ticket_id as string
  );
  const { data: candidateTickets, error: candidateTicketError } = await supabase
    .from("tickets")
    .select("id, target_entry_group_ids")
    .in("id", ticketIds);

  if (candidateTicketError) {
    return errorResponse("Failed to load candidate tickets", 500);
  }

  const candidateTicketMap = new Map(
    (candidateTickets ?? []).map((ticket) => [ticket.id as string, ticket]),
  );

  const candidateGroupIds = new Set<string>();
  for (const participant of candidateParticipantRows) {
    const ticket = candidateTicketMap.get(participant.ticket_id as string);
    const groups = Array.isArray(ticket?.target_entry_group_ids)
      ? [...ticket.target_entry_group_ids as string[]]
      : [];
    if (groups.length === 0) {
      return errorResponse("그룹 정보를 확인할 수 없습니다", 400);
    }
    for (const groupId of groups) {
      candidateGroupIds.add(groupId);
    }
  }

  const { data: rules, error: rulesError } = await supabase
    .from("match_rules")
    .select("target_group_id, vote_count")
    .eq("event_id", eventId)
    .in("source_group_id", voterGroupIds)
    .in("target_group_id", [...candidateGroupIds]);

  if (rulesError) return errorResponse("Failed to load match rules", 500);
  if (!rules || rules.length === 0) {
    return errorResponse("매칭 대상이 아닙니다", 400);
  }

  const allowedGroupIds = new Set(
    rules
      .map((row) => row["target_group_id"] as string | null)
      .filter((value): value is string => Boolean(value)),
  );

  for (const participant of candidateParticipantRows) {
    const ticket = candidateTicketMap.get(participant.ticket_id as string);
    const groups = Array.isArray(ticket?.target_entry_group_ids)
      ? [...ticket.target_entry_group_ids as string[]]
      : [];
    if (!groups.some((groupId) => allowedGroupIds.has(groupId))) {
      return errorResponse("매칭 대상이 아닌 참가자가 포함되어 있습니다", 400);
    }
  }

  // Use the most permissive (max) vote_count across all applicable rules.
  // Voters in multiple source groups receive the highest quota among their rules;
  // the DB RPC enforces the actual per-user limit via p_max_vote_count.
  const maxVoteCount = rules.reduce((current, row) => {
    const value = typeof row["vote_count"] === "number"
      ? row["vote_count"] as number
      : 1;
    return current > value ? current : value;
  }, 1);

  const { data: rpcData, error: rpcError } = await supabase.rpc(
    "commit_match_likes",
    {
      p_event_id: eventId,
      p_voter_id: voterId,
      p_candidate_ids: normalizedCandidateIds,
      p_max_vote_count: maxVoteCount,
    },
  );

  if (rpcError) {
    // P0001 is the stable ERRCODE raised by commit_match_likes when the per-user quota is exceeded.
    // Matching on .code is more robust than matching on the localized Korean message string.
    if (rpcError.code === "P0001") {
      return errorResponse("좋아요 수를 초과했습니다", 400);
    }
    return errorResponse(rpcError.message, 500);
  }

  const result = Array.isArray(rpcData) && rpcData.length > 0
    ? (rpcData[0] as Record<string, unknown>)
    : {};

  return successResponse({
    "success": true,
    "requested_count": normalizedCandidateIds.length,
    "inserted_count": result["inserted_count"] ?? 0,
    "duplicate_count": result["duplicate_count"] ?? 0,
  });
}));
