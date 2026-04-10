// Fix #1235: verifyRefundEligibility unit tests — includes event-started guard
import { assertEquals } from "@std/assert";
import { verifyRefundEligibility } from "./refund_utils.ts";

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
  const paidAt = new Date(now.getTime() - ms(1)).toISOString(); // 1시간 전 결제
  const eventStartTime = new Date(now.getTime() + days(3)).toISOString(); // 3일 후 이벤트

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
  const paidAt = new Date(now.getTime() - ms(5)).toISOString(); // 5시간 전 결제 (grace 불합격)
  const eventStartTime = new Date(now.getTime() + days(10)).toISOString(); // 10일 후 이벤트

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
  const paidAt = new Date(now.getTime() - ms(1)).toISOString(); // 1시간 전 결제 (grace 합격 조건)
  const eventStartTime = new Date(now.getTime() - ms(1)).toISOString(); // 1시간 전 이벤트 시작

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
  const eventStartTime = now.toISOString(); // 정확히 지금 시작

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
  const paidAt = new Date(now.getTime() - ms(5)).toISOString(); // 5시간 전 결제 (grace 불합격)
  const eventStartTime = new Date(now.getTime() + days(3)).toISOString(); // 3일 후 이벤트 (cutoff 불합격)

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
  const eventStartTime = new Date(now.getTime() + days(10)).toISOString(); // 10일 후

  const result = verifyRefundEligibility({
    paidAt: null,
    eventStartTime,
    gracePeriodHours: GRACE_HOURS,
    cutoffDays: CUTOFF_DAYS,
    now,
  });

  assertEquals(result.eligible, true);
});
