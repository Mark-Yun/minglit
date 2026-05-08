// event-matching/index.ts — Create match pairs for checked-in participants of an event

import {
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
// Fix #2185 (Batch 2): migrate to minglitEdgeFunction wrapper — auth via manifest (system caller)
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { log } from "../_shared/logger.ts";

const FN = "event-matching";

export const handler = async (req: Request, { supabase }: EFContext): Promise<Response> => {
  const body = await parseJsonBody(req);
  if (body instanceof Response) return body;

  const { event_id } = body as { event_id?: string };

  if (!event_id) {
    return errorResponse("Missing required parameter: event_id", 400);
  }

  // Check idempotency: if match_pairs already exist for this event, return existing
  const { data: existingPairs, error: existingErr } = await supabase
    .from("match_pairs")
    .select("id, user_lower_id, user_higher_id")
    .eq("event_id", event_id);

  if (existingErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to check existing pairs",
      metadata: { detail: existingErr.message },
    });
    return errorResponse("Failed to check existing match pairs", 500);
  }

  if (existingPairs && existingPairs.length > 0) {
    log({
      function: FN,
      level: "info",
      message: "Match pairs already exist, returning existing",
      metadata: { event_id, count: existingPairs.length },
    });
    return successResponse({
      success: true,
      match_count: existingPairs.length,
      pairs: (existingPairs as Array<
        { id: string; user_lower_id: string; user_higher_id: string }
      >).map((p) => ({
        user1: p.user_lower_id,
        user2: p.user_higher_id,
      })),
      idempotent: true,
    });
  }

  // Fetch entry groups for this event
  const { data: groups, error: groupsErr } = await supabase
    .from("entry_groups")
    .select("id, gender")
    .eq("event_id", event_id)
    .order("id");

  if (groupsErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch entry_groups",
      metadata: { detail: groupsErr.message },
    });
    return errorResponse("Failed to fetch entry groups", 500);
  }

  if (!groups || groups.length < 2) {
    return errorResponse(
      "Event must have at least 2 entry groups for matching",
      400,
    );
  }

  const groupList = groups as Array<{ id: string; gender: string }>;
  const groupAId = groupList[0].id;
  const groupBId = groupList[1].id;

  // Fetch checked-in participants split by group
  const { data: participants, error: partErr } = await supabase
    .from("event_participants")
    .select("id, user_id, entry_group_id")
    .eq("event_id", event_id)
    .eq("status", "checked_in");

  if (partErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to fetch participants",
      metadata: { detail: partErr.message },
    });
    return errorResponse("Failed to fetch checked-in participants", 500);
  }

  const partList = (participants ?? []) as Array<
    { id: string; user_id: string; entry_group_id: string }
  >;
  const groupAParticipants = partList.filter((p) =>
    p.entry_group_id === groupAId
  );
  const groupBParticipants = partList.filter((p) =>
    p.entry_group_id === groupBId
  );

  if (groupAParticipants.length === 0 || groupBParticipants.length === 0) {
    return errorResponse(
      "Both groups must have checked-in participants for matching",
      400,
    );
  }

  // Create match pairs: pair up across groups (up to min count)
  const pairsToInsert: Array<
    { event_id: string; user_lower_id: string; user_higher_id: string }
  > = [];
  const minCount = Math.min(
    groupAParticipants.length,
    groupBParticipants.length,
  );

  for (let i = 0; i < minCount; i++) {
    const userA = groupAParticipants[i].user_id;
    const userB = groupBParticipants[i].user_id;
    const lowerUserId = userA < userB ? userA : userB;
    const higherUserId = userA < userB ? userB : userA;
    pairsToInsert.push({
      event_id,
      user_lower_id: lowerUserId,
      user_higher_id: higherUserId,
    });
  }

  const { data: insertedPairs, error: insertErr } = await supabase
    .from("match_pairs")
    .insert(pairsToInsert)
    .select("id, user_lower_id, user_higher_id");

  if (insertErr) {
    log({
      function: FN,
      level: "error",
      message: "Failed to insert match pairs",
      metadata: { detail: insertErr.message },
    });
    return errorResponse("Failed to create match pairs", 500);
  }

  const resultPairs = (insertedPairs ?? []) as Array<
    { id: string; user_lower_id: string; user_higher_id: string }
  >;

  log({
    function: FN,
    level: "info",
    message: "Match pairs created",
    metadata: { event_id, match_count: resultPairs.length },
  });

  return successResponse({
    success: true,
    match_count: resultPairs.length,
    pairs: resultPairs.map((p) => ({
      user1: p.user_lower_id,
      user2: p.user_higher_id,
    })),
    idempotent: false,
  });
};

minglitEdgeFunction(handler);
