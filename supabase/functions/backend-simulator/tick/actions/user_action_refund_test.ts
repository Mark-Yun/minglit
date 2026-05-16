// tick/actions/user_action_refund_test.ts — UserActionRefund unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { UserActionRefund } from "./user_action_refund.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const USER_ID = "user-1";
const EVENT_ID = "event-1";
const APPLICATION_ID = "app-1";

function newAction() {
  return new UserActionRefund(USER_ID, APPLICATION_ID, EVENT_ID, TOKEN);
}

Deno.test({
  name: "UserActionRefund - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "user_refund");
    assertEquals(action.ef, "user-cancel-order");
    assertEquals(action.actorId, USER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(USER_ID), true);
    assertEquals(action.description.includes(APPLICATION_ID), true);
    assertEquals(action.description.includes(EVENT_ID), true);
  },
});

Deno.test({
  name: "UserActionRefund.buildParams - returns event_id only",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { event_id: EVENT_ID });
  },
});

Deno.test({
  name: "UserActionRefund.assertEFResponse - passes on 200",
  fn: () => {
    const response: EFResponse = { status: 200, data: {} };
    const result = newAction().assertEFResponse(response);
    assertEquals(result.passed, true);
    assertEquals(result.name, "refund_ef_ok");
  },
});

Deno.test({
  name: "UserActionRefund.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 403, 404, 409, 500]) {
      const result = newAction().assertEFResponse({ status, data: {} });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

/** Build mock for refund assertDBState: controls both event_applications and event_participants. */
function buildDBMock(opts: {
  application?: { status: string } | null;
  applicationError?: { message: string } | null;
  participant?: { id: string } | null;
  participantError?: { message: string } | null;
}) {
  return createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({
          data: opts.application ?? null,
          error: opts.applicationError ?? null,
        }),
      },
      event_participants: {
        select: () => ({
          data: opts.participant ?? null,
          error: opts.participantError ?? null,
        }),
      },
    },
  });
}

Deno.test({
  name: "UserActionRefund.assertDBState - passes when application cancelled and participant removed",
  fn: async () => {
    const mock = buildDBMock({
      application: { status: "cancelled" },
      participant: null, // removed
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.name, "refund_db_ok");
  },
});

Deno.test({
  name: "UserActionRefund.assertDBState - fails when application row missing",
  fn: async () => {
    const mock = buildDBMock({ application: null, participant: null });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "refund_db_application");
  },
});

Deno.test({
  name: "UserActionRefund.assertDBState - fails when application status is not cancelled",
  fn: async () => {
    for (const status of ["paid", "pending_review", "approved", "refunded"]) {
      const mock = buildDBMock({ application: { status }, participant: null });
      const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
      assertEquals(result.passed, false, `status=${status} must fail refund assertion`);
      assertEquals(result.name, "refund_db_application_status");
    }
  },
});

Deno.test({
  // Regression guard: refund EF must NOT leave a stale participant row.
  // If participant cleanup is silently dropped, this test catches it.
  name: "UserActionRefund.assertDBState - fails when participant row still exists after refund",
  fn: async () => {
    const mock = buildDBMock({
      application: { status: "cancelled" },
      participant: { id: "participant-stale" },
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "refund_db_participant_removed");
  },
});

Deno.test({
  name: "UserActionRefund.assertDBState - fails on application query error",
  fn: async () => {
    const mock = buildDBMock({
      application: null,
      applicationError: { message: "deadlock detected" },
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "refund_db_application");
    assertEquals(result.details.includes("deadlock detected"), true);
  },
});

Deno.test({
  name: "UserActionRefund.assertDBState - fails on participant query error",
  fn: async () => {
    const mock = buildDBMock({
      application: { status: "cancelled" },
      participantError: { message: "rls policy violation" },
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "refund_db_participant");
    assertEquals(result.details.includes("rls policy violation"), true);
  },
});
