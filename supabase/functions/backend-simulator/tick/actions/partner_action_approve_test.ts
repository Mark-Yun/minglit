// tick/actions/partner_action_approve_test.ts — PartnerActionApprove unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { PartnerActionApprove } from "./partner_action_approve.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const PARTNER_ID = "partner-1";
const APPLICATION_ID = "app-1";
const EVENT_ID = "event-1";
const USER_ID = "user-1";

function newAction() {
  return new PartnerActionApprove(PARTNER_ID, APPLICATION_ID, TOKEN);
}

Deno.test({
  name: "PartnerActionApprove - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "partner_approve");
    assertEquals(action.ef, "partner-approve-application");
    assertEquals(action.actorId, PARTNER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(PARTNER_ID), true);
    assertEquals(action.description.includes(APPLICATION_ID), true);
  },
});

Deno.test({
  name: "PartnerActionApprove.buildParams - returns application_id",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { application_id: APPLICATION_ID });
  },
});

Deno.test({
  name: "PartnerActionApprove.assertEFResponse - passes on 200",
  fn: () => {
    const result = newAction().assertEFResponse({ status: 200, data: {} });
    assertEquals(result.passed, true);
    assertEquals(result.name, "partner_approve_ef_ok");
  },
});

Deno.test({
  name: "PartnerActionApprove.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 404, 500]) {
      const result = newAction().assertEFResponse({ status, data: {} });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

/** Build mock for approve assertDBState: controls event_applications and event_participants. */
function buildDBMock(opts: {
  application?: { id: string; status: string; event_id: string; user_id: string } | null;
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
  name: "PartnerActionApprove.assertDBState - passes when application approved + participant created",
  fn: async () => {
    const mock = buildDBMock({
      application: { id: APPLICATION_ID, status: "approved", event_id: EVENT_ID, user_id: USER_ID },
      participant: { id: "participant-1" },
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.name, "partner_approve_db_ok");
  },
});

Deno.test({
  name: "PartnerActionApprove.assertDBState - fails when application row missing",
  fn: async () => {
    const mock = buildDBMock({ application: null });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_approve_db_application");
  },
});

Deno.test({
  name: "PartnerActionApprove.assertDBState - fails when application status is not approved",
  fn: async () => {
    for (const status of ["pending_review", "rejected", "cancelled", "paid"]) {
      const mock = buildDBMock({
        application: { id: APPLICATION_ID, status, event_id: EVENT_ID, user_id: USER_ID },
      });
      const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
      assertEquals(result.passed, false, `status=${status} must fail approve assertion`);
      assertEquals(result.name, "partner_approve_db_application_status");
    }
  },
});

Deno.test({
  // Regression guard: approve EF must create event_participants row.
  // If the trigger/EF logic is broken and only updates application status,
  // participant query returns null → this test catches the partial state.
  name: "PartnerActionApprove.assertDBState - fails when participant row not created after approval",
  fn: async () => {
    const mock = buildDBMock({
      application: { id: APPLICATION_ID, status: "approved", event_id: EVENT_ID, user_id: USER_ID },
      participant: null, // missing
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_approve_db_participant");
    assertEquals(result.details.includes(EVENT_ID), true);
    assertEquals(result.details.includes(USER_ID), true);
  },
});

Deno.test({
  name: "PartnerActionApprove.assertDBState - fails on application query error",
  fn: async () => {
    const mock = buildDBMock({
      applicationError: { message: "permission denied" },
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_approve_db_application");
    assertEquals(result.details.includes("permission denied"), true);
  },
});

Deno.test({
  name: "PartnerActionApprove.assertDBState - fails on participant query error",
  fn: async () => {
    const mock = buildDBMock({
      application: { id: APPLICATION_ID, status: "approved", event_id: EVENT_ID, user_id: USER_ID },
      participantError: { message: "lock timeout" },
    });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_approve_db_participant");
    assertEquals(result.details.includes("lock timeout"), true);
  },
});
