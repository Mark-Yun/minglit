// v2/invariant/blocking_test.ts — blockingRefundDenied invariant 단위 테스트

import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { blockingRefundDenied } from "./blocking.ts";

/** Mock supabase that returns canned RPC result */
function mockSupabase(opts: {
  data?: Array<Record<string, unknown>> | null;
  error?: { message: string } | null;
}): SupabaseClient {
  return {
    // deno-lint-ignore no-explicit-any
    rpc(_name: string, _args?: any) {
      return Promise.resolve({ data: opts.data ?? null, error: opts.error ?? null });
    },
  } as unknown as SupabaseClient;
}

Deno.test({
  name: "blockingRefundDenied - identity",
  fn: () => {
    assertEquals(blockingRefundDenied.name, "blocked_partner_refund_denied");
    assertEquals(typeof blockingRefundDenied.description, "string");
  },
});

Deno.test({
  name: "blockingRefundDenied.check - returns empty when no violations",
  fn: async () => {
    const supabase = mockSupabase({ data: [] });
    const violations = await blockingRefundDenied.check(supabase);
    assertEquals(violations.length, 0);
  },
});

Deno.test({
  name: "blockingRefundDenied.check - returns violation per row",
  fn: async () => {
    const supabase = mockSupabase({
      data: [
        { application_id: "a-1", refund_id: "r-1", user_id: "u-1", partner_id: "p-1" },
        { application_id: "a-2", refund_id: "r-2", user_id: "u-2", partner_id: "p-1" },
      ],
    });
    const violations = await blockingRefundDenied.check(supabase);
    assertEquals(violations.length, 2);
    assertEquals(violations[0].invariant, "blocked_partner_refund_denied");
    assertEquals(
      (violations[0].details as Record<string, unknown>).application_id,
      "a-1",
    );
  },
});

Deno.test({
  name: "blockingRefundDenied.check - surfaces RPC error as a violation",
  fn: async () => {
    const supabase = mockSupabase({ error: { message: "permission denied" } });
    const violations = await blockingRefundDenied.check(supabase);
    assertEquals(violations.length, 1);
    const detail = violations[0].details as Record<string, unknown>;
    assertEquals(detail.kind, "rpc_error");
    assertEquals(detail.message, "permission denied");
  },
});
