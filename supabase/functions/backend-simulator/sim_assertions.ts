// sim_assertions.ts — E2E Simulation Assertion Functions (6 Phases)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimAssertionResult, SimRefundCalc } from "./sim_types.ts";

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

function pass(check_name: string, expected: unknown, actual: unknown): SimAssertionResult {
  return { check_name, passed: true, expected, actual };
}

function fail(check_name: string, expected: unknown, actual: unknown, details?: string): SimAssertionResult {
  return { check_name, passed: false, expected, actual, details };
}

// ─────────────────────────────────────────────────────────
// Phase 2 — 신청 검증
// ─────────────────────────────────────────────────────────

export async function simAssertParticipantCreated(
  supabase: SupabaseClient,
  eventId: string,
  userId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_participants")
      .select("id")
      .eq("event_id", eventId)
      .eq("user_id", userId)
      .maybeSingle();
    if (error) return fail("participant_created", true, false, error.message);
    return data
      ? pass("participant_created", true, true)
      : fail("participant_created", true, false, `No participant row for event=${eventId} user=${userId}`);
  } catch (e) {
    return fail("participant_created", true, false, String(e));
  }
}

export async function simAssertParticipantCount(
  supabase: SupabaseClient,
  eventId: string,
  expectedCount: number,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("events")
      .select("current_participants")
      .eq("id", eventId)
      .single();
    if (error) return fail("participant_count", expectedCount, null, error.message);
    const actual = data?.current_participants ?? null;
    return actual === expectedCount
      ? pass("participant_count", expectedCount, actual)
      : fail("participant_count", expectedCount, actual, `events.current_participants mismatch`);
  } catch (e) {
    return fail("participant_count", expectedCount, null, String(e));
  }
}

export async function simAssertTicketSoldCount(
  supabase: SupabaseClient,
  ticketId: string,
  expectedCount: number,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("tickets")
      .select("sold_count")
      .eq("id", ticketId)
      .single();
    if (error) return fail("ticket_sold_count", expectedCount, null, error.message);
    const actual = data?.sold_count ?? null;
    return actual === expectedCount
      ? pass("ticket_sold_count", expectedCount, actual)
      : fail("ticket_sold_count", expectedCount, actual, `tickets.sold_count mismatch`);
  } catch (e) {
    return fail("ticket_sold_count", expectedCount, null, String(e));
  }
}

// ─────────────────────────────────────────────────────────
// Phase 3 — 승인 / 거절 검증
// ─────────────────────────────────────────────────────────

export async function simAssertApplicationApproved(
  supabase: SupabaseClient,
  applicationId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_applications")
      .select("status")
      .eq("id", applicationId)
      .single();
    if (error) return fail("application_approved", "approved|paid", null, error.message);
    const actual = data?.status ?? null;
    const approved = actual === "approved" || actual === "paid";
    return approved
      ? pass("application_approved", "approved|paid", actual)
      : fail("application_approved", "approved|paid", actual, `status is '${actual}', expected approved or paid`);
  } catch (e) {
    return fail("application_approved", "approved|paid", null, String(e));
  }
}

export async function simAssertApplicationRejected(
  supabase: SupabaseClient,
  applicationId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_applications")
      .select("status, refund_status")
      .eq("id", applicationId)
      .single();
    if (error) return fail("application_rejected", "rejected", null, error.message);
    const actual = data?.status ?? null;
    return actual === "rejected"
      ? pass("application_rejected", "rejected", actual)
      : fail("application_rejected", "rejected", actual, `status is '${actual}', expected rejected`);
  } catch (e) {
    return fail("application_rejected", "rejected", null, String(e));
  }
}

export async function simAssertVerificationApproved(
  supabase: SupabaseClient,
  submissionId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("verification_submissions")
      .select("status, partner_id, user_id, verification_id")
      .eq("id", submissionId)
      .single();
    if (error) return fail("verification_approved", "approved", null, error.message);
    const actualStatus = data?.status ?? null;
    if (actualStatus !== "approved") {
      return fail("verification_approved", "approved", actualStatus, `submission status is '${actualStatus}'`);
    }
    // Also check that partner_verified_users row was created by the trigger
    // Fix #181: partner_verified_users has composite PK (partner_id, user_id, verification_id), no 'id' column
    const { data: pvuData, error: pvuErr } = await supabase
      .from("partner_verified_users")
      .select("submission_id")
      .eq("partner_id", data.partner_id)
      .eq("user_id", data.user_id)
      .eq("verification_id", data.verification_id)
      .maybeSingle();
    if (pvuErr) return fail("verification_approved", "approved+pvu", "approved", pvuErr.message);
    return pvuData
      ? pass("verification_approved", "approved+pvu", "approved+pvu")
      : fail("verification_approved", "approved+pvu", "approved only", "partner_verified_users row missing after approval");
  } catch (e) {
    return fail("verification_approved", "approved", null, String(e));
  }
}

// ─────────────────────────────────────────────────────────
// Phase 4 — 환불 검증
// ─────────────────────────────────────────────────────────

// Fix #133: 환불 시뮬레이션 로직을 binary DB-driven 정책(100%/0%)으로 정렬
export function simCalcRefund(
  startTime: Date,
  paymentAmount: number,
  now: Date = new Date(),
  paidAt: Date | null = null,
  gracePeriodHours: number = 2,
  cutoffDays: number = 7,
): SimRefundCalc {
  const withinGracePeriod =
    paidAt !== null &&
    paidAt.getTime() <= now.getTime() &&
    now.getTime() - paidAt.getTime() <= gracePeriodHours * 60 * 60 * 1000;

  const withinCutoff =
    startTime.getTime() - now.getTime() >= cutoffDays * 24 * 60 * 60 * 1000;

  const percentage = withinGracePeriod || withinCutoff ? 100 : 0;
  const refundAmount = Math.floor((paymentAmount * percentage) / 100);
  const feeAmount = paymentAmount - refundAmount;
  return { refund_percentage: percentage, refund_amount: refundAmount, fee_amount: feeAmount };
}

export async function simAssertRefundProcessed(
  supabase: SupabaseClient,
  applicationId: string,
  expectedAmount: number,
  expectedPercentage: number,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_applications")
      .select("status, refund_status, refund_amount")
      .eq("id", applicationId)
      .single();
    if (error) return fail("refund_processed", { amount: expectedAmount, percentage: expectedPercentage }, null, error.message);

    const actualAmount = data?.refund_amount ?? null;
    const actualStatus = data?.refund_status ?? null;

    const amountOk = actualAmount === expectedAmount;
    const statusOk = actualStatus === "completed" || actualStatus === "requested";

    if (!statusOk) {
      return fail("refund_processed", "completed|requested", actualStatus, `refund_status is '${actualStatus}'`);
    }
    if (!amountOk) {
      return fail("refund_processed", expectedAmount, actualAmount, `refund_amount mismatch (expected ${expectedAmount}, got ${actualAmount})`);
    }
    return pass("refund_processed", { amount: expectedAmount, percentage: expectedPercentage }, { amount: actualAmount, status: actualStatus });
  } catch (e) {
    return fail("refund_processed", expectedAmount, null, String(e));
  }
}

// ─────────────────────────────────────────────────────────
// Phase 5 — 체크인 / 매칭 검증
// ─────────────────────────────────────────────────────────

export async function simAssertCheckedIn(
  supabase: SupabaseClient,
  participantId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_participants")
      .select("status")
      .eq("id", participantId)
      .single();
    if (error) return fail("checked_in", "checked_in", null, error.message);
    const actual = data?.status ?? null;
    return actual === "checked_in"
      ? pass("checked_in", "checked_in", actual)
      : fail("checked_in", "checked_in", actual, `status is '${actual}'`);
  } catch (e) {
    return fail("checked_in", "checked_in", null, String(e));
  }
}

export async function simAssertNoShow(
  supabase: SupabaseClient,
  participantId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_participants")
      .select("status")
      .eq("id", participantId)
      .single();
    if (error) return fail("no_show", "no_show", null, error.message);
    const actual = data?.status ?? null;
    return actual === "no_show"
      ? pass("no_show", "no_show", actual)
      : fail("no_show", "no_show", actual, `status is '${actual}'`);
  } catch (e) {
    return fail("no_show", "no_show", null, String(e));
  }
}

export async function simAssertMatchPairCreated(
  supabase: SupabaseClient,
  eventId: string,
  userId1: string,
  userId2: string,
): Promise<SimAssertionResult> {
  try {
    // match_pairs CHECK: user_lower_id < user_higher_id
    const lowerUserId = userId1 < userId2 ? userId1 : userId2;
    const higherUserId = userId1 < userId2 ? userId2 : userId1;

    const { data, error } = await supabase
      .from("match_pairs")
      .select("id")
      .eq("event_id", eventId)
      .eq("user_lower_id", lowerUserId)
      .eq("user_higher_id", higherUserId)
      .maybeSingle();
    if (error) return fail("match_pair_created", true, false, error.message);
    return data
      ? pass("match_pair_created", true, true)
      : fail("match_pair_created", true, false, `No match_pair for users ${lowerUserId} / ${higherUserId} in event ${eventId}`);
  } catch (e) {
    return fail("match_pair_created", true, false, String(e));
  }
}

export async function simAssertCheckinRatio(
  supabase: SupabaseClient,
  eventId: string,
  expectedCheckinRate: number,
  tolerance: number,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("event_participants")
      .select("status")
      .eq("event_id", eventId);
    if (error) return fail("checkin_ratio", expectedCheckinRate, null, error.message);
    const participants = (data ?? []) as { status: string }[];
    const total = participants.length;
    if (total === 0) return fail("checkin_ratio", expectedCheckinRate, 0, "No participants found");

    const checkedIn = participants.filter((p) => p.status === "checked_in").length;
    const actualRate = checkedIn / total;
    const withinTolerance = Math.abs(actualRate - expectedCheckinRate) <= tolerance;

    return withinTolerance
      ? pass("checkin_ratio", expectedCheckinRate, actualRate)
      : fail("checkin_ratio", expectedCheckinRate, actualRate,
          `Rate ${actualRate.toFixed(2)} is outside tolerance ±${tolerance} from expected ${expectedCheckinRate}`);
  } catch (e) {
    return fail("checkin_ratio", expectedCheckinRate, null, String(e));
  }
}

// ─────────────────────────────────────────────────────────
// Phase 6 — 정산 검증
// ─────────────────────────────────────────────────────────

export async function simAssertSettlementCreated(
  supabase: SupabaseClient,
  eventId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("settlement_items")
      .select("id, status")
      .eq("source_id", eventId)
      .eq("source_type", "EVENT")
      .maybeSingle();
    if (error) return fail("settlement_created", "PENDING", null, error.message);
    if (!data) return fail("settlement_created", "PENDING", null, `No settlement_items row for event=${eventId}`);
    return data.status === "PENDING"
      ? pass("settlement_created", "PENDING", data.status)
      : fail("settlement_created", "PENDING", data.status, `status is '${data.status}'`);
  } catch (e) {
    return fail("settlement_created", "PENDING", null, String(e));
  }
}

export async function simAssertSettlementAmounts(
  supabase: SupabaseClient,
  settlementId: string,
  expectedGross: number,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("settlement_items")
      .select("gross_amount, platform_fee_amount, pg_fee_amount, vat_amount, net_amount")
      .eq("id", settlementId)
      .single();
    if (error) return fail("settlement_amounts", expectedGross, null, error.message);

    const gross = data?.gross_amount ?? 0;
    const platformFee = data?.platform_fee_amount ?? 0;
    const pgFee = data?.pg_fee_amount ?? 0;
    const vat = data?.vat_amount ?? 0;
    const net = data?.net_amount ?? 0;

    // Expected calculations (floor)
    const expectedPlatformFee = Math.floor(expectedGross * 5 / 100);
    const expectedPgFee = Math.floor(expectedGross * 35 / 1000); // 3.5%
    const expectedVat = Math.floor((expectedPlatformFee + expectedPgFee) * 10 / 100);
    const expectedNet = expectedGross - expectedPlatformFee - expectedPgFee - expectedVat;

    if (gross !== expectedGross) {
      return fail("settlement_amounts", expectedGross, gross, `gross_amount mismatch`);
    }
    if (platformFee !== expectedPlatformFee) {
      return fail("settlement_amounts", expectedPlatformFee, platformFee, `platform_fee_amount mismatch`);
    }
    if (pgFee !== expectedPgFee) {
      return fail("settlement_amounts", expectedPgFee, pgFee, `pg_fee_amount mismatch`);
    }
    if (vat !== expectedVat) {
      return fail("settlement_amounts", expectedVat, vat, `vat_amount mismatch`);
    }
    if (net !== expectedNet) {
      return fail("settlement_amounts", expectedNet, net, `net_amount mismatch`);
    }

    return pass("settlement_amounts", { gross: expectedGross, platform_fee: expectedPlatformFee, pg_fee: expectedPgFee, vat: expectedVat, net: expectedNet },
      { gross, platform_fee: platformFee, pg_fee: pgFee, vat, net });
  } catch (e) {
    return fail("settlement_amounts", expectedGross, null, String(e));
  }
}

export async function simAssertSettlementReady(
  supabase: SupabaseClient,
  settlementId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("settlement_items")
      .select("status")
      .eq("id", settlementId)
      .single();
    if (error) return fail("settlement_ready", "READY", null, error.message);
    const actual = data?.status ?? null;
    return actual === "READY"
      ? pass("settlement_ready", "READY", actual)
      : fail("settlement_ready", "READY", actual, `status is '${actual}'`);
  } catch (e) {
    return fail("settlement_ready", "READY", null, String(e));
  }
}

export async function simAssertSettlementChecksum(
  supabase: SupabaseClient,
  settlementId: string,
): Promise<SimAssertionResult> {
  try {
    const { data, error } = await supabase
      .from("settlement_items")
      .select("calc_checksum")
      .eq("id", settlementId)
      .single();
    if (error) return fail("settlement_checksum", "64-char hex", null, error.message);
    const checksum = data?.calc_checksum ?? null;
    if (!checksum) return fail("settlement_checksum", "64-char hex", null, "calc_checksum is null");
    const valid = typeof checksum === "string" && checksum.length === 64 && /^[0-9a-f]+$/i.test(checksum);
    return valid
      ? pass("settlement_checksum", "64-char hex", checksum)
      : fail("settlement_checksum", "64-char hex", checksum, `checksum is '${checksum}' (length=${checksum?.length})`);
  } catch (e) {
    return fail("settlement_checksum", "64-char hex", null, String(e));
  }
}
