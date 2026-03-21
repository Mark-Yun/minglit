// sim_assertions_test.ts — Unit Tests for sim_assertions.ts

import { assertEquals } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import {
  simCalcRefund,
  simAssertParticipantCreated,
  simAssertParticipantCount,
  simAssertTicketSoldCount,
  simAssertApplicationApproved,
  simAssertApplicationRejected,
  simAssertVerificationApproved,
  simAssertRefundProcessed,
  simAssertCheckedIn,
  simAssertNoShow,
  simAssertMatchPairCreated,
  simAssertCheckinRatio,
  simAssertSettlementCreated,
  simAssertSettlementAmounts,
  simAssertSettlementReady,
  simAssertSettlementChecksum,
} from "./sim_assertions.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

// ─────────────────────────────────────────────────────────
// simCalcRefund — binary policy (100% or 0%)
// ─────────────────────────────────────────────────────────

Deno.test("simCalcRefund - 7d+ returns 100%", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 8 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 100);
  assertEquals(result.refund_amount, 10000);
  assertEquals(result.fee_amount, 0);
});

Deno.test("simCalcRefund - exactly 7d returns 100%", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 100);
  assertEquals(result.refund_amount, 10000);
  assertEquals(result.fee_amount, 0);
});

Deno.test("simCalcRefund - 3-7d returns 0% (binary policy)", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 0);
  assertEquals(result.refund_amount, 0);
  assertEquals(result.fee_amount, 10000);
});

Deno.test("simCalcRefund - exactly 3d returns 0% (binary policy)", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 0);
  assertEquals(result.refund_amount, 0);
  assertEquals(result.fee_amount, 10000);
});

Deno.test("simCalcRefund - 1-3d returns 0% (binary policy)", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 0);
  assertEquals(result.refund_amount, 0);
  assertEquals(result.fee_amount, 10000);
});

Deno.test("simCalcRefund - exactly 1d returns 0% (binary policy)", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 0);
  assertEquals(result.refund_amount, 0);
  assertEquals(result.fee_amount, 10000);
});

Deno.test("simCalcRefund - <1d returns 0%", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 12 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10000, now);
  assertEquals(result.refund_percentage, 0);
  assertEquals(result.refund_amount, 0);
  assertEquals(result.fee_amount, 10000);
});

Deno.test("simCalcRefund - floor math (100% case)", () => {
  const now = new Date();
  const startTime = new Date(now.getTime() + 8 * 24 * 60 * 60 * 1000);
  const result = simCalcRefund(startTime, 10001, now);
  assertEquals(result.refund_amount, 10001);
  assertEquals(result.fee_amount, 0);
});

// ─────────────────────────────────────────────────────────
// Phase 2 — simAssertParticipantCreated
// ─────────────────────────────────────────────────────────

Deno.test("simAssertParticipantCreated - passes when row exists", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: { id: "part-1" }, error: null }),
      },
    },
  });
  const result = await simAssertParticipantCreated(mock as unknown as SupabaseClient, "event-1", "user-1");
  assertEquals(result.passed, true);
  assertEquals(result.check_name, "participant_created");
});

Deno.test("simAssertParticipantCreated - fails when row missing", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: null, error: null }),
      },
    },
  });
  const result = await simAssertParticipantCreated(mock as unknown as SupabaseClient, "event-1", "user-1");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 2 — simAssertParticipantCount
// ─────────────────────────────────────────────────────────

Deno.test("simAssertParticipantCount - passes when count matches", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      events: {
        select: () => ({ data: { current_participants: 5 }, error: null }),
      },
    },
  });
  const result = await simAssertParticipantCount(mock as unknown as SupabaseClient, "event-1", 5);
  assertEquals(result.passed, true);
});

Deno.test("simAssertParticipantCount - fails when count differs", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      events: {
        select: () => ({ data: { current_participants: 3 }, error: null }),
      },
    },
  });
  const result = await simAssertParticipantCount(mock as unknown as SupabaseClient, "event-1", 5);
  assertEquals(result.passed, false);
  assertEquals(result.actual, 3);
  assertEquals(result.expected, 5);
});

// ─────────────────────────────────────────────────────────
// Phase 2 — simAssertTicketSoldCount
// ─────────────────────────────────────────────────────────

Deno.test("simAssertTicketSoldCount - passes when sold_count matches", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      tickets: {
        select: () => ({ data: { sold_count: 3 }, error: null }),
      },
    },
  });
  const result = await simAssertTicketSoldCount(mock as unknown as SupabaseClient, "ticket-1", 3);
  assertEquals(result.passed, true);
});

// ─────────────────────────────────────────────────────────
// Phase 3 — simAssertApplicationApproved
// ─────────────────────────────────────────────────────────

Deno.test("simAssertApplicationApproved - passes for 'approved'", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: { status: "approved" }, error: null }),
      },
    },
  });
  const result = await simAssertApplicationApproved(mock as unknown as SupabaseClient, "app-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertApplicationApproved - passes for 'paid'", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: { status: "paid" }, error: null }),
      },
    },
  });
  const result = await simAssertApplicationApproved(mock as unknown as SupabaseClient, "app-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertApplicationApproved - fails for 'pending'", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: { status: "pending" }, error: null }),
      },
    },
  });
  const result = await simAssertApplicationApproved(mock as unknown as SupabaseClient, "app-1");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 3 — simAssertApplicationRejected
// ─────────────────────────────────────────────────────────

Deno.test("simAssertApplicationRejected - passes for 'rejected'", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: { status: "rejected", refund_status: "completed" }, error: null }),
      },
    },
  });
  const result = await simAssertApplicationRejected(mock as unknown as SupabaseClient, "app-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertApplicationRejected - fails for 'approved'", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: { status: "approved", refund_status: null }, error: null }),
      },
    },
  });
  const result = await simAssertApplicationRejected(mock as unknown as SupabaseClient, "app-1");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 3 — simAssertVerificationApproved
// ─────────────────────────────────────────────────────────

Deno.test("simAssertVerificationApproved - passes when approved + pvu exists", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      verification_submissions: {
        select: () => ({
          data: { status: "approved", partner_id: "partner-1", user_id: "user-1", verification_id: "verif-1" },
          error: null,
        }),
      },
      partner_verified_users: {
        select: () => ({ data: { submission_id: "pvu-1" }, error: null }),
      },
    },
  });
  const result = await simAssertVerificationApproved(mock as unknown as SupabaseClient, "sub-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertVerificationApproved - fails when status is pending", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      verification_submissions: {
        select: () => ({
          data: { status: "pending", partner_id: "partner-1", user_id: "user-1", verification_id: "verif-1" },
          error: null,
        }),
      },
    },
  });
  const result = await simAssertVerificationApproved(mock as unknown as SupabaseClient, "sub-1");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 4 — simAssertRefundProcessed
// ─────────────────────────────────────────────────────────

Deno.test("simAssertRefundProcessed - passes with correct amount", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({
          data: { status: "cancelled", refund_status: "completed", refund_amount: 8000 },
          error: null,
        }),
      },
    },
  });
  const result = await simAssertRefundProcessed(mock as unknown as SupabaseClient, "app-1", 8000, 80);
  assertEquals(result.passed, true);
});

Deno.test("simAssertRefundProcessed - fails with wrong amount", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({
          data: { status: "cancelled", refund_status: "completed", refund_amount: 5000 },
          error: null,
        }),
      },
    },
  });
  const result = await simAssertRefundProcessed(mock as unknown as SupabaseClient, "app-1", 8000, 80);
  assertEquals(result.passed, false);
  assertEquals(result.actual, 5000);
  assertEquals(result.expected, 8000);
});

// ─────────────────────────────────────────────────────────
// Phase 5 — simAssertCheckedIn / simAssertNoShow
// ─────────────────────────────────────────────────────────

Deno.test("simAssertCheckedIn - passes for checked_in", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: { status: "checked_in" }, error: null }),
      },
    },
  });
  const result = await simAssertCheckedIn(mock as unknown as SupabaseClient, "part-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertCheckedIn - fails for ticket_issued", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: { status: "ticket_issued" }, error: null }),
      },
    },
  });
  const result = await simAssertCheckedIn(mock as unknown as SupabaseClient, "part-1");
  assertEquals(result.passed, false);
});

Deno.test("simAssertNoShow - passes for no_show", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: { status: "no_show" }, error: null }),
      },
    },
  });
  const result = await simAssertNoShow(mock as unknown as SupabaseClient, "part-1");
  assertEquals(result.passed, true);
});

// ─────────────────────────────────────────────────────────
// Phase 5 — simAssertMatchPairCreated
// ─────────────────────────────────────────────────────────

Deno.test("simAssertMatchPairCreated - passes when pair exists (user1 < user2)", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      match_pairs: {
        select: () => ({ data: { id: "mp-1" }, error: null }),
      },
    },
  });
  const result = await simAssertMatchPairCreated(mock as unknown as SupabaseClient, "event-1", "aaa-user", "bbb-user");
  assertEquals(result.passed, true);
});

Deno.test("simAssertMatchPairCreated - passes when pair exists (user2 < user1 ordering flipped)", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      match_pairs: {
        select: () => ({ data: { id: "mp-1" }, error: null }),
      },
    },
  });
  // userId2 < userId1 lexicographically — should flip ordering
  const result = await simAssertMatchPairCreated(mock as unknown as SupabaseClient, "event-1", "bbb-user", "aaa-user");
  assertEquals(result.passed, true);
});

Deno.test("simAssertMatchPairCreated - fails when pair missing", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      match_pairs: {
        select: () => ({ data: null, error: null }),
      },
    },
  });
  const result = await simAssertMatchPairCreated(mock as unknown as SupabaseClient, "event-1", "user-1", "user-2");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 5 — simAssertCheckinRatio
// ─────────────────────────────────────────────────────────

Deno.test("simAssertCheckinRatio - passes when within tolerance", async () => {
  // 7/10 = 70% checked_in
  const participants = [
    ...Array(7).fill({ status: "checked_in" }),
    ...Array(3).fill({ status: "no_show" }),
  ];
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: participants, error: null }),
      },
    },
  });
  const result = await simAssertCheckinRatio(mock as unknown as SupabaseClient, "event-1", 0.7, 0.15);
  assertEquals(result.passed, true);
});

Deno.test("simAssertCheckinRatio - fails when outside tolerance", async () => {
  // 3/10 = 30% checked_in (expected 70% ±15%)
  const participants = [
    ...Array(3).fill({ status: "checked_in" }),
    ...Array(7).fill({ status: "no_show" }),
  ];
  const mock = createMockSupabaseClient({
    tables: {
      event_participants: {
        select: () => ({ data: participants, error: null }),
      },
    },
  });
  const result = await simAssertCheckinRatio(mock as unknown as SupabaseClient, "event-1", 0.7, 0.15);
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 6 — simAssertSettlementCreated
// ─────────────────────────────────────────────────────────

Deno.test("simAssertSettlementCreated - passes when PENDING settlement exists", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: { id: "si-1", status: "PENDING" }, error: null }),
      },
    },
  });
  const result = await simAssertSettlementCreated(mock as unknown as SupabaseClient, "event-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertSettlementCreated - fails when no row", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: null, error: null }),
      },
    },
  });
  const result = await simAssertSettlementCreated(mock as unknown as SupabaseClient, "event-1");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 6 — simAssertSettlementAmounts
// ─────────────────────────────────────────────────────────

Deno.test("simAssertSettlementAmounts - passes with correct fee calculation", async () => {
  const gross = 100000;
  const platformFee = Math.floor(gross * 5 / 100); // 5000
  const pgFee = Math.floor(gross * 35 / 1000); // 3500
  const vat = Math.floor((platformFee + pgFee) * 10 / 100); // 850
  const net = gross - platformFee - pgFee - vat; // 90650

  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({
          data: { gross_amount: gross, platform_fee_amount: platformFee, pg_fee_amount: pgFee, vat_amount: vat, net_amount: net },
          error: null,
        }),
      },
    },
  });
  const result = await simAssertSettlementAmounts(mock as unknown as SupabaseClient, "si-1", gross);
  assertEquals(result.passed, true);
});

Deno.test("simAssertSettlementAmounts - fails with wrong platform_fee", async () => {
  const gross = 100000;
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({
          data: {
            gross_amount: gross,
            platform_fee_amount: 9999, // wrong
            pg_fee_amount: Math.floor(gross * 35 / 1000),
            vat_amount: 850,
            net_amount: gross - 9999 - 3500 - 850,
          },
          error: null,
        }),
      },
    },
  });
  const result = await simAssertSettlementAmounts(mock as unknown as SupabaseClient, "si-1", gross);
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 6 — simAssertSettlementReady
// ─────────────────────────────────────────────────────────

Deno.test("simAssertSettlementReady - passes for READY", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: { status: "READY" }, error: null }),
      },
    },
  });
  const result = await simAssertSettlementReady(mock as unknown as SupabaseClient, "si-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertSettlementReady - fails for PENDING", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: { status: "PENDING" }, error: null }),
      },
    },
  });
  const result = await simAssertSettlementReady(mock as unknown as SupabaseClient, "si-1");
  assertEquals(result.passed, false);
});

// ─────────────────────────────────────────────────────────
// Phase 6 — simAssertSettlementChecksum
// ─────────────────────────────────────────────────────────

Deno.test("simAssertSettlementChecksum - passes with valid 64-char hex", async () => {
  const validChecksum = "a".repeat(64);
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: { calc_checksum: validChecksum }, error: null }),
      },
    },
  });
  const result = await simAssertSettlementChecksum(mock as unknown as SupabaseClient, "si-1");
  assertEquals(result.passed, true);
});

Deno.test("simAssertSettlementChecksum - fails with null checksum", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: { calc_checksum: null }, error: null }),
      },
    },
  });
  const result = await simAssertSettlementChecksum(mock as unknown as SupabaseClient, "si-1");
  assertEquals(result.passed, false);
});

Deno.test("simAssertSettlementChecksum - fails with wrong length checksum", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: { calc_checksum: "abc123" }, error: null }),
      },
    },
  });
  const result = await simAssertSettlementChecksum(mock as unknown as SupabaseClient, "si-1");
  assertEquals(result.passed, false);
});
