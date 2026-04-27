import { assertEquals } from "@std/assert";
import {
  createMockSupabaseClient,
} from "../../_test_utils/mock_supabase_client.ts";
import { handleUpdateStatus } from "./update_status.ts";

const TEST_USER_ID = "user-partner-owner";
const TEST_PARTNER_ID = "partner-001";
const TEST_PARTY_ID = "party-001";

function partyFound(partnerId = TEST_PARTNER_ID) {
  return {
    parties: {
      select: () => ({
        data: { id: TEST_PARTY_ID, partner_id: partnerId },
        error: null,
      }),
      update: () => ({ data: null, error: null }),
    },
  };
}

function partyNotFound() {
  return {
    parties: {
      select: () => ({ data: null, error: null }),
    },
  };
}

function permGranted() {
  return {
    partner_member_permissions: {
      select: () => ({
        data: { partner_id: TEST_PARTNER_ID, permissions: ["PARTY_MANAGE"] },
        error: null,
      }),
    },
  };
}

function permDenied() {
  return {
    partner_member_permissions: {
      select: () => ({ data: null, error: null }),
    },
  };
}

Deno.test({
  name: "update_status: missing party_id returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient();
    const res = await handleUpdateStatus(
      { status: "closed" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "Missing party_id");
  },
});

Deno.test({
  name: "update_status: invalid status returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient();
    const res = await handleUpdateStatus(
      { party_id: TEST_PARTY_ID, status: "invalid_status" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error.includes("Invalid status"), true);
  },
});

Deno.test({
  name: "update_status: party not found returns 404",
  fn: async () => {
    const supabase = createMockSupabaseClient({ tables: partyNotFound() });
    const res = await handleUpdateStatus(
      { party_id: "nonexistent", status: "closed" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 404);
    const body = await res.json();
    assertEquals(body.error, "Party not found");
  },
});

Deno.test({
  name: "update_status: no permission returns 403",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound("other-partner"), ...permDenied() },
    });
    const res = await handleUpdateStatus(
      { party_id: TEST_PARTY_ID, status: "closed" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 403);
  },
});

Deno.test({
  name: "update_status: success — active to closed",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound(), ...permGranted() },
    });
    const res = await handleUpdateStatus(
      { party_id: TEST_PARTY_ID, status: "closed" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.success, true);
  },
});

Deno.test({
  name: "update_status: draft status succeeds",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound(), ...permGranted() },
    });
    const res = await handleUpdateStatus(
      { party_id: TEST_PARTY_ID, status: "draft" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.success, true);
  },
});
