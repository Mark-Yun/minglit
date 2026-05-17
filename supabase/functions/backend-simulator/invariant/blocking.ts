// v2/invariant/blocking.ts — Cross-EF: blocked partner 의 event 에 환불 가지 않음

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Invariant, InvariantViolation } from "./_registry.ts";
import { registerInvariant } from "./_registry.ts";

/**
 * 규칙: 유저가 partner 를 block 한 후엔 그 partner 의 event 에 대한 환불 (refund) row 가
 * 새로 생기지 않아야 함. block 이후의 refund 는 EF 가 거부해야 정상.
 *
 * 본 invariant 는 raw SQL 로 violations 직접 조회.
 * (위반 = block.created_at < refund.created_at 인 row 존재)
 */
export const blockingRefundDenied: Invariant = {
  name: "blocked_partner_refund_denied",
  description:
    "유저가 partner 를 block 한 시점 이후에 생성된 환불 row 가 존재하면 위반. " +
    "EF user-cancel-order 가 block 상태를 검사해 거부해야 함.",

  async check(supabase: SupabaseClient): Promise<InvariantViolation[]> {
    const { data, error } = await supabase.rpc("sim_invariant_blocking_refund_denied");

    if (error) {
      return [{
        invariant: this.name,
        details: { kind: "rpc_error", message: error.message },
      }];
    }

    const violations = (data as Array<Record<string, unknown>>) ?? [];
    return violations.map((row) => ({
      invariant: this.name,
      details: row,
    }));
  },
};

registerInvariant(blockingRefundDenied);
