import { assertEquals } from "@std/assert";
import {
  createMockSupabaseClient,
} from "../../_test_utils/mock_supabase_client.ts";
import { getPartnerEmail } from "./auth.ts";

Deno.test({
  name: "getPartnerEmail reads partner_member_permissions",
  fn: async () => {
    let permissionsQueried = false;
    let legacyTableQueried = false;
    const supabase = createMockSupabaseClient({
      tables: {
        partner_member_permissions: {
          select: ({ filters }) => {
            permissionsQueried = true;
            assertEquals(filters.partner_id, "partner-1");
            return { data: [{ user_id: "user-1" }], error: null };
          },
        },
        partner_members: {
          select: () => {
            legacyTableQueried = true;
            return { data: [], error: null };
          },
        },
      },
      authAdminGetUserById: (userId) => {
        assertEquals(userId, "user-1");
        return {
          data: { user: { email: "partner@example.com" } },
          error: null,
        };
      },
    });

    const email = await getPartnerEmail(
      // deno-lint-ignore no-explicit-any
      supabase as any,
      "partner-1",
    );

    assertEquals(email, "partner@example.com");
    assertEquals(permissionsQueried, true);
    assertEquals(legacyTableQueried, false);
  },
});
