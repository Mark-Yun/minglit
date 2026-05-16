// tick/actions/user_action_vote_test.ts — UserActionVote unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { UserActionVote } from "./user_action_vote.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const USER_ID = "user-voter";
const EVENT_ID = "event-1";
const CANDIDATE_ID = "user-candidate";

function newAction() {
  return new UserActionVote(USER_ID, EVENT_ID, CANDIDATE_ID, TOKEN);
}

Deno.test({
  name: "UserActionVote - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "user_vote");
    assertEquals(action.ef, "user-cast-vote");
    assertEquals(action.actorId, USER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(USER_ID), true);
    assertEquals(action.description.includes(CANDIDATE_ID), true);
    assertEquals(action.description.includes(EVENT_ID), true);
  },
});

Deno.test({
  name: "UserActionVote.buildParams - returns event_id + candidate_id",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { event_id: EVENT_ID, candidate_id: CANDIDATE_ID });
  },
});

Deno.test({
  name: "UserActionVote.assertEFResponse - passes on 200",
  fn: () => {
    const result = newAction().assertEFResponse({ status: 200, data: {} });
    assertEquals(result.passed, true);
    assertEquals(result.name, "vote_ef_ok");
  },
});

Deno.test({
  name: "UserActionVote.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 404, 409, 500]) {
      const result = newAction().assertEFResponse({ status, data: {} });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

function mockWithVote(row: { id: string } | null, error: { message: string } | null = null) {
  return createMockSupabaseClient({
    tables: {
      match_votes: {
        select: () => ({ data: row, error }),
      },
    },
  });
}

Deno.test({
  name: "UserActionVote.assertDBState - passes when match_votes row exists",
  fn: async () => {
    const mock = mockWithVote({ id: "vote-1" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("vote-1"), true);
  },
});

Deno.test({
  // Critical regression guard: vote insertion must produce a row.
  // If EF silently dedupes/no-ops without inserting, this test catches it.
  name: "UserActionVote.assertDBState - fails when match_votes row missing after EF call",
  fn: async () => {
    const mock = mockWithVote(null);
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "vote_db_row");
    assertEquals(result.details.includes(USER_ID), true);
    assertEquals(result.details.includes(CANDIDATE_ID), true);
    assertEquals(result.details.includes(EVENT_ID), true);
  },
});

Deno.test({
  name: "UserActionVote.assertDBState - fails on DB query error",
  fn: async () => {
    const mock = mockWithVote(null, { message: "unique violation" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "vote_db_row");
    assertEquals(result.details.includes("unique violation"), true);
  },
});
