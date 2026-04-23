// Fix #1783: requirePartnerPermission 단위 테스트
// — owner bypass 회귀 방지
// — permissions 배열 ANY 매칭 검증
import { assertEquals } from "@std/assert";

import { requirePartnerPermission } from "./partner_permissions.ts";

const PARTNER_ID = "partner-001";
const USER_ID = "user-001";

// Minimal Supabase client mock — only stubs the permission query chain
function mockSupabase(
  permData: { role: string; permissions: string[] } | null,
  permError: { message: string } | null = null,
// deno-lint-ignore no-explicit-any
): any {
  return {
    from: () => ({
      select: () => ({
        eq: () => ({
          eq: () => ({
            maybeSingle: () => Promise.resolve({ data: permData, error: permError }),
          }),
        }),
      }),
    }),
  };
}

Deno.test("requirePartnerPermission — owner bypasses permission array check", async () => {
  // owner with empty permissions array — should still pass (ownerBypass: true default)
  const supabase = mockSupabase({ role: "owner", permissions: [] });
  const result = await requirePartnerPermission(supabase, PARTNER_ID, USER_ID, ["PARTY_MANAGE"]);
  assertEquals(result, null, "owner should pass even with empty permissions");
});

Deno.test("requirePartnerPermission — member with matching permission passes", async () => {
  const supabase = mockSupabase({ role: "manager", permissions: ["PARTY_MANAGE"] });
  const result = await requirePartnerPermission(supabase, PARTNER_ID, USER_ID, ["PARTY_MANAGE"]);
  assertEquals(result, null, "member with matching permission should pass");
});

Deno.test("requirePartnerPermission — member without permission returns 403", async () => {
  const supabase = mockSupabase({ role: "staff", permissions: ["PARTNER_EDIT"] });
  const result = await requirePartnerPermission(supabase, PARTNER_ID, USER_ID, ["PARTY_MANAGE"]);
  assertEquals(result?.status, 403, "member without matching permission should return 403");
});

Deno.test("requirePartnerPermission — ANY matching in required array passes", async () => {
  const supabase = mockSupabase({ role: "manager", permissions: ["APPLICATION_MANAGE"] });
  const result = await requirePartnerPermission(
    supabase, PARTNER_ID, USER_ID,
    ["EVENT_MANAGE", "APPLICATION_MANAGE"],
  );
  assertEquals(result, null, "ANY match in required array should pass");
});

Deno.test("requirePartnerPermission — no permission record returns 403", async () => {
  const supabase = mockSupabase(null);
  const result = await requirePartnerPermission(supabase, PARTNER_ID, USER_ID, ["PARTY_MANAGE"]);
  assertEquals(result?.status, 403, "no permission record should return 403");
});

Deno.test("requirePartnerPermission — DB error returns 500", async () => {
  const supabase = mockSupabase(null, { message: "DB connection failed" });
  const result = await requirePartnerPermission(supabase, PARTNER_ID, USER_ID, ["PARTY_MANAGE"]);
  assertEquals(result?.status, 500, "DB error should return 500");
});

Deno.test("requirePartnerPermission — ownerBypass: false blocks owner without permission", async () => {
  const supabase = mockSupabase({ role: "owner", permissions: [] });
  const result = await requirePartnerPermission(
    supabase, PARTNER_ID, USER_ID,
    ["PARTY_MANAGE"],
    { ownerBypass: false },
  );
  assertEquals(result?.status, 403, "owner with ownerBypass: false should be blocked");
});
