import { assertEquals } from "@std/assert";
import {
  createMockSupabaseClient,
} from "../../_test_utils/mock_supabase_client.ts";
import { handleCreate } from "./create.ts";

const TEST_USER_ID = "user-partner-owner";
const TEST_PARTNER_ID = "partner-001";
const TEST_PARTY_ID = "party-001";
const TEST_LOCATION_ID = "loc-001";

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
  name: "create: missing partner_id returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient();
    const res = await handleCreate(
      { party: { title: "테스트" } },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "Missing partner_id");
  },
});

Deno.test({
  name: "create: missing party object returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient();
    const res = await handleCreate(
      { partner_id: TEST_PARTNER_ID },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "Missing or invalid party object");
  },
});

Deno.test({
  name: "create: missing party title returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient();
    const res = await handleCreate(
      { partner_id: TEST_PARTNER_ID, party: { description: "no title" } },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "Missing party title");
  },
});

Deno.test({
  name: "create: invalid status returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient({ tables: permGranted() });
    const res = await handleCreate(
      {
        partner_id: TEST_PARTNER_ID,
        party: { title: "테스트", status: "invalid" },
      },
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
  name: "create: tag_ids not array returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient({ tables: permGranted() });
    const res = await handleCreate(
      {
        partner_id: TEST_PARTNER_ID,
        party: { title: "테스트" },
        tag_ids: "not-an-array",
      },
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
  name: "create: tag_ids exceeding 5 returns 400",
  fn: async () => {
    const supabase = createMockSupabaseClient({ tables: permGranted() });
    const res = await handleCreate(
      {
        partner_id: TEST_PARTNER_ID,
        party: { title: "테스트" },
        tag_ids: [
          "00000000-0000-0000-0000-000000000001",
          "00000000-0000-0000-0000-000000000002",
          "00000000-0000-0000-0000-000000000003",
          "00000000-0000-0000-0000-000000000004",
          "00000000-0000-0000-0000-000000000005",
          "00000000-0000-0000-0000-000000000006",
        ],
      },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 400);
    const body = await res.json();
    assertEquals(body.error, "tag_ids must contain at most 5 tags");
  },
});

Deno.test({
  name: "create: no PARTY_MANAGE permission returns 403",
  fn: async () => {
    const supabase = createMockSupabaseClient({ tables: permDenied() });
    const res = await handleCreate(
      { partner_id: TEST_PARTNER_ID, party: { title: "테스트" } },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 403);
  },
});

Deno.test({
  name: "create: success — party created without location",
  fn: async () => {
    const supabase = createMockSupabaseClient({
      tables: permGranted(),
      rpcs: {
        create_party_with_tags: () => ({ data: TEST_PARTY_ID, error: null }),
      },
    });
    const res = await handleCreate(
      {
        partner_id: TEST_PARTNER_ID,
        party: { title: "대학생 밍글" },
      },
      // deno-lint-ignore no-explicit-any
      supabase as any,
      TEST_USER_ID,
    );
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.success, true);
    assertEquals(body.party_id, TEST_PARTY_ID);
  },
});
