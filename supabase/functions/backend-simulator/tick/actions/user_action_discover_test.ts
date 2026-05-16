// tick/actions/user_action_discover_test.ts — UserActionDiscover unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { UserActionDiscover } from "./user_action_discover.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const USER_ID = "user-1";

function newAction() {
  return new UserActionDiscover(USER_ID, TOKEN);
}

Deno.test({
  name: "UserActionDiscover - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "user_discover");
    assertEquals(action.ef, "user-event-feed");
    assertEquals(action.actorId, USER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(USER_ID), true);
  },
});

Deno.test({
  name: "UserActionDiscover.buildParams - returns limit=20",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { limit: 20 });
  },
});

Deno.test({
  name: "UserActionDiscover.assertEFResponse - passes on 200 with empty events array",
  fn: () => {
    const response: EFResponse = { status: 200, data: { events: [] } };
    const result = newAction().assertEFResponse(response);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("count=0"), true);
  },
});

Deno.test({
  name: "UserActionDiscover.assertEFResponse - passes on 200 with populated events array",
  fn: () => {
    const response: EFResponse = {
      status: 200,
      data: { events: [{ id: "e1" }, { id: "e2" }, { id: "e3" }] },
    };
    const result = newAction().assertEFResponse(response);
    assertEquals(result.passed, true);
    assertEquals(result.details.includes("count=3"), true);
  },
});

Deno.test({
  name: "UserActionDiscover.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 404, 500]) {
      const result = newAction().assertEFResponse({ status, data: { events: [] } });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

Deno.test({
  name: "UserActionDiscover.assertEFResponse - fails when events field missing",
  fn: () => {
    const result = newAction().assertEFResponse({ status: 200, data: {} });
    assertEquals(result.passed, false);
    assertEquals(result.name, "discover_ef_events");
  },
});

Deno.test({
  // Regression guard: non-array events (object/string/null) must fail since SUT calls .length downstream
  name: "UserActionDiscover.assertEFResponse - fails when events is non-array",
  fn: () => {
    for (const events of [null, "string", 42, { fake: true }]) {
      const result = newAction().assertEFResponse({ status: 200, data: { events } });
      assertEquals(result.passed, false, `events=${JSON.stringify(events)} must fail`);
      assertEquals(result.name, "discover_ef_events");
    }
  },
});

Deno.test({
  // Read-only action: SUT must always return passed=true regardless of DB state
  name: "UserActionDiscover.assertDBState - always passes (read-only action)",
  fn: async () => {
    const mock = createMockSupabaseClient({});
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.name, "discover_db_skip");
  },
});
