// tick/actions/user_action_checkin_test.ts — UserActionCheckin unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { UserActionCheckin } from "./user_action_checkin.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const USER_ID = "user-1";
const EVENT_ID = "event-1";
const PARTICIPANT_ID = "participant-1";

function newAction() {
  return new UserActionCheckin(USER_ID, EVENT_ID, PARTICIPANT_ID, TOKEN);
}

Deno.test({
  name: "UserActionCheckin - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "user_checkin");
    assertEquals(action.ef, "event-checkin");
    assertEquals(action.actorId, USER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(USER_ID), true);
    assertEquals(action.description.includes(EVENT_ID), true);
  },
});

Deno.test({
  name: "UserActionCheckin.buildParams - returns event_id + participant_id",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { event_id: EVENT_ID, participant_id: PARTICIPANT_ID });
  },
});

Deno.test({
  name: "UserActionCheckin.assertEFResponse - passes on 200",
  fn: () => {
    const response: EFResponse = { status: 200, data: {} };
    const result = newAction().assertEFResponse(response);
    assertEquals(result.passed, true);
    assertEquals(result.name, "checkin_ef_ok");
  },
});

Deno.test({
  name: "UserActionCheckin.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 404, 409, 500]) {
      const result = newAction().assertEFResponse({ status, data: {} });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

function mockWithParticipant(row: { status: string } | null, error: { message: string } | null = null) {
  return createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: row, error }),
      },
    },
  });
}

Deno.test({
  name: "UserActionCheckin.assertDBState - passes when participant status=checked_in",
  fn: async () => {
    const mock = mockWithParticipant({ status: "checked_in" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("checked_in"), true);
  },
});

Deno.test({
  name: "UserActionCheckin.assertDBState - fails when participant row missing",
  fn: async () => {
    const mock = mockWithParticipant(null);
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "checkin_db_participant");
  },
});

Deno.test({
  name: "UserActionCheckin.assertDBState - fails when status is not checked_in",
  fn: async () => {
    for (const status of ["ticket_issued", "no_show", "cancelled", "applied"]) {
      const mock = mockWithParticipant({ status });
      const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
      assertEquals(result.passed, false, `status=${status} must fail checkin assertion`);
      assertEquals(result.name, "checkin_db_status");
    }
  },
});

Deno.test({
  name: "UserActionCheckin.assertDBState - fails when DB query errors",
  fn: async () => {
    const mock = mockWithParticipant(null, { message: "timeout" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.details.includes("timeout"), true);
  },
});
