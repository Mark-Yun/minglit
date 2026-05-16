// tick/actions/partner_action_reject_test.ts — PartnerActionReject unit tests (#1331)

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createMockSupabaseClient } from "../../../_test_utils/mock_supabase_client.ts";
import { PartnerActionReject } from "./partner_action_reject.ts";
import type { EFResponse } from "../tick_types.ts";

const TOKEN = "test-token";
const PARTNER_ID = "partner-1";
const APPLICATION_ID = "app-1";

function newAction() {
  return new PartnerActionReject(PARTNER_ID, APPLICATION_ID, TOKEN);
}

Deno.test({
  name: "PartnerActionReject - identity fields wired correctly",
  fn: () => {
    const action = newAction();
    assertEquals(action.type, "partner_reject");
    assertEquals(action.ef, "partner-reject-application");
    assertEquals(action.actorId, PARTNER_ID);
    assertEquals(action.token, TOKEN);
    assertEquals(action.description.includes(PARTNER_ID), true);
    assertEquals(action.description.includes(APPLICATION_ID), true);
  },
});

Deno.test({
  name: "PartnerActionReject.buildParams - returns application_id",
  fn: () => {
    const params = newAction().buildParams();
    assertEquals(params, { application_id: APPLICATION_ID });
  },
});

Deno.test({
  name: "PartnerActionReject.assertEFResponse - passes on 200",
  fn: () => {
    const result = newAction().assertEFResponse({ status: 200, data: {} });
    assertEquals(result.passed, true);
    assertEquals(result.name, "partner_reject_ef_ok");
  },
});

Deno.test({
  name: "PartnerActionReject.assertEFResponse - fails on non-200 status",
  fn: () => {
    for (const status of [400, 401, 403, 404, 500]) {
      const result = newAction().assertEFResponse({ status, data: {} });
      assertEquals(result.passed, false, `status=${status} must fail`);
      assertEquals(result.details.includes(String(status)), true);
    }
  },
});

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
  name: "PartnerActionReject.assertDBState - passes when application status=rejected",
  fn: async () => {
    const mock = mockWithApplication({ id: APPLICATION_ID, status: "rejected" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, true);
    assertEquals(result.name, "partner_reject_db_ok");
  },
});

Deno.test({
  name: "PartnerActionReject.assertDBState - fails when application row missing",
  fn: async () => {
    const mock = mockWithApplication(null);
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_reject_db_application");
  },
});

Deno.test({
  // Regression guard: ensure approve/reject paths don't get crossed — 'approved' must NOT
  // be accepted as a valid reject outcome.
  name: "PartnerActionReject.assertDBState - fails when application status is not rejected",
  fn: async () => {
    for (const status of ["pending_review", "approved", "cancelled", "paid"]) {
      const mock = mockWithApplication({ id: APPLICATION_ID, status });
      const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
      assertEquals(result.passed, false, `status=${status} must fail reject assertion`);
      assertEquals(result.name, "partner_reject_db_application_status");
    }
  },
});

Deno.test({
  name: "PartnerActionReject.assertDBState - fails on DB query error",
  fn: async () => {
    const mock = mockWithApplication(null, { message: "constraint violation" });
    const result = await newAction().assertDBState(mock as unknown as SupabaseClient);
    assertEquals(result.passed, false);
    assertEquals(result.name, "partner_reject_db_application");
    assertEquals(result.details.includes("constraint violation"), true);
  },
});
