import { assertEquals } from "@std/assert";
import {
  createMockSupabaseClient,
} from "../../_test_utils/mock_supabase_client.ts";
import { handleUpdate } from "./update.ts";

const TEST_USER_ID = "user-partner-owner";
const TEST_PARTNER_ID = "partner-001";
const TEST_PARTY_ID = "party-001";

function partyFound(partnerId = TEST_PARTNER_ID) {
  return {
    parties: {
      select: () => ({
        data: { id: TEST_PARTY_ID, partner_id: partnerId, location_id: null },
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
  name: "update: missing party_id returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient();
    const res = await handleUpdate(
      { party: { title: "test" } },
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
  name: "update: party not found returns 404",
  fn: async () => {
    const supabase = createMockSupabaseClient({ tables: partyNotFound() });
    const res = await handleUpdate(
      { party_id: "nonexistent", party: { title: "test" } },
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
  name: "update: no fields to update returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound(), ...permGranted() },
    });
    const res = await handleUpdate(
      { party_id: TEST_PARTY_ID },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "No fields to update");
  },
});

Deno.test({
  name: "update: no permission returns 403",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound("other-partner"), ...permDenied() },
    });
    const res = await handleUpdate(
      { party_id: TEST_PARTY_ID, party: { title: "해킹시도" } },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 403);
  },
});

Deno.test({
  name: "update: tag_ids not array returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound(), ...permGranted() },
    });
    const res = await handleUpdate(
      { party_id: TEST_PARTY_ID, tag_ids: "not-an-array" },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "tag_ids must be an array");
  },
});

Deno.test({
  name: "update: success — party title updated",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: { ...partyFound(), ...permGranted() },
    });
    const res = await handleUpdate(
      { party_id: TEST_PARTY_ID, party: { title: "수정된 제목" } },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.success, true);
  },
});
