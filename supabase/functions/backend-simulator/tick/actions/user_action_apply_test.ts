// tick/actions/user_action_apply_test.ts — UserActionApplyEvent unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { UserActionApplyEvent } from "./user_action_apply.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const USER_ID = "user-1";
const EVENT_ID = "event-1";
const TICKET_ID = "ticket-1";

function newAction() {
  return new UserActionApplyEvent(USER_ID, EVENT_ID, TICKET_ID, TOKEN);
}

// ============================================================
// Identity + buildParams
// ============================================================

Deno.test({
  name: "UserActionApplyEvent - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "user_apply");
    assertEquals(action.ef, "apply-event");
    assertEquals(action.actorId, USER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(USER_ID), true);
    assertEquals(action.description.includes(EVENT_ID), true);
  },
});

Deno.test({
  name: "UserActionApplyEvent.buildParams - returns event_id + ticket_id",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { event_id: EVENT_ID, ticket_id: TICKET_ID });
  },
});

// ============================================================
// assertEFResponse
// ============================================================

Deno.test({
  name: "UserActionApplyEvent.assertEFResponse - passes on 200 with application_id",
  fn: () => {
    const response: EFResponse = { status: 200, data: { application_id: "app-1" } };
    const result = newAction().assertEFResponse(response);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("app-1"), true);
  },
});

Deno.test({
  name: "UserActionApplyEvent.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 404, 500, 502]) {
      const result = newAction().assertEFResponse({ status, data: { application_id: "app-1" } });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

Deno.test({
  name: "UserActionApplyEvent.assertEFResponse - fails when application_id missing on 200",
  fn: () => {
    const result = newAction().assertEFResponse({ status: 200, data: {} });
    assertEquals(result.passed, false);
    assertEquals(result.name, "apply_ef_application_id");
  },
});

Deno.test({
  // Regression guard: an EF that returns application_id as falsy (empty string, null, 0)
  // must be treated as a missing field. SUT uses `!response.data?.application_id`.
  name: "UserActionApplyEvent.assertEFResponse - fails when application_id is falsy",
  fn: () => {
    for (const falsy of ["", null, 0]) {
      const result = newAction().assertEFResponse({ status: 200, data: { application_id: falsy } });
      assertEquals(result.passed, false, `application_id=${JSON.stringify(falsy)} must fail`);
      assertEquals(result.name, "apply_ef_application_id");
    }
  },
});

// ============================================================
// assertDBState
// ============================================================

function mockWithApplication(row: { id: string; status: string } | null, error: { message: string } | null = null) {
  return createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: row, error }),
      },
    },
  });
}

Deno.test({
  name: "UserActionApplyEvent.assertDBState - passes when row exists with status=paid",
  fn: async () => {
    const mock = mockWithApplication({ id: "app-1", status: "paid" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("paid"), true);
  },
});

Deno.test({
  name: "UserActionApplyEvent.assertDBState - passes when row exists with status=pending_review",
  fn: async () => {
    const mock = mockWithApplication({ id: "app-1", status: "pending_review" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("pending_review"), true);
  },
});

Deno.test({
  name: "UserActionApplyEvent.assertDBState - fails when application row missing",
  fn: async () => {
    const mock = mockWithApplication(null);
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "apply_db_row");
  },
});

Deno.test({
  name: "UserActionApplyEvent.assertDBState - fails on unexpected application status",
  fn: async () => {
    for (const status of ["cancelled", "refunded", "rejected", "approved"]) {
      const mock = mockWithApplication({ id: "app-1", status });
      const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
      assertEquals(result.passed, false, `status=${status} must fail apply assertion`);
      assertEquals(result.name, "apply_db_status");
    }
  },
});

Deno.test({
  name: "UserActionApplyEvent.assertDBState - fails when DB query errors",
  fn: async () => {
    const mock = mockWithApplication(null, { message: "connection refused" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.details.includes("connection refused"), true);
  },
});
