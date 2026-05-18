// _shared/domains/payment/refund_policy_test.ts
// pure unit tests — mock 0, IO 0

import { assertEquals } from "jsr:@std/assert@1";
import { parseRefundPolicy, verifyRefundEligibility } from "./refund_policy.ts";

// ─── parseRefundPolicy ─────────────────────────────────────────────────────────

Deno.test("parseRefundPolicy — 정상 값 → 그대로 사용", () => {
  assertEquals(
    parseRefundPolicy({ grace_period_hours: 4, cutoff_days: 14 }),
    { gracePeriodHours: 4, cutoffDays: 14 },
  );
});

Deno.test("parseRefundPolicy — 누락 / 빈 객체 → 기본값 (2h / 7d)", () => {
  assertEquals(parseRefundPolicy({}), { gracePeriodHours: 2, cutoffDays: 7 });
  assertEquals(parseRefundPolicy(null), { gracePeriodHours: 2, cutoffDays: 7 });
  assertEquals(parseRefundPolicy(undefined), { gracePeriodHours: 2, cutoffDays: 7 });
});

Deno.test("parseRefundPolicy — 깨진 타입 / 음수 → 기본값으로 폴백", () => {
  assertEquals(
    parseRefundPolicy({ grace_period_hours: "4", cutoff_days: -1 }),
    { gracePeriodHours: 2, cutoffDays: 7 },
  );
});

Deno.test("parseRefundPolicy — 부분 누락 → 누락된 쪽만 기본값", () => {
  assertEquals(
    parseRefundPolicy({ grace_period_hours: 6 }),
    { gracePeriodHours: 6, cutoffDays: 7 },
  );
});

// ─── verifyRefundEligibility ───────────────────────────────────────────────────


const GRACE_HOURS = 2;
const CUTOFF_DAYS = 7;

function ms(hours: number): number {
  return hours * 60 * 60 * 1000;
}

function days(d: number): number {
  return d * 24 * 60 * 60 * 1000;
}

Deno.test("verifyRefundEligibility - event not started + within grace → eligible", () => {
  const now = new Date();
  const paidAt = new Date(now.getTime() - ms(1)).toISOString();
  const eventStartTime = new Date(now.getTime() + days(3)).toISOString();

  const result = verifyRefundEligibility({
    paidAt,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, true);
});

Deno.test("verifyRefundEligibility - event not started + within cutoff → eligible", () => {
  const now = new Date();
  const paidAt = new Date(now.getTime() - ms(5)).toISOString();
  const eventStartTime = new Date(now.getTime() + days(10)).toISOString();

  const result = verifyRefundEligibility({
    paidAt,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, true);
});

// Fix #1235: 이벤트 시작 후 예매 취소 차단 핵심 케이스
Deno.test("verifyRefundEligibility - event already started → not eligible", () => {
  const now = new Date();
  const paidAt = new Date(now.getTime() - ms(1)).toISOString();
  const eventStartTime = new Date(now.getTime() - ms(1)).toISOString();

  const result = verifyRefundEligibility({
    paidAt,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, false);
  assertEquals(result.reason, "Event has already started");
});

Deno.test("verifyRefundEligibility - event just started (exactly now) → not eligible", () => {
  const now = new Date();
  const paidAt = new Date(now.getTime() - ms(1)).toISOString();
  const eventStartTime = now.toISOString();

  const result = verifyRefundEligibility({
    paidAt,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, false);
  assertEquals(result.reason, "Event has already started");
});

Deno.test("verifyRefundEligibility - event not started + grace expired + cutoff too soon → not eligible", () => {
  const now = new Date();
  const paidAt = new Date(now.getTime() - ms(5)).toISOString();
  const eventStartTime = new Date(now.getTime() + days(3)).toISOString();

  const result = verifyRefundEligibility({
    paidAt,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, false);
  assertEquals(result.reason, "Refund window has expired");
});

Deno.test("verifyRefundEligibility - paidAt null + event not started + within cutoff → eligible", () => {
  const now = new Date();
  const eventStartTime = new Date(now.getTime() + days(10)).toISOString();

  const result = verifyRefundEligibility({
    paidAt: null,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, true);
});
