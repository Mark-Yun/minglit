// _shared/domains/payment/application_status_test.ts
// pure unit tests — mock 0, IO 0, ms 단위로 통과

import { assertEquals } from "jsr:@std/assert@1";
import {
  classifyApplicationStatus,
  isEventStarted,
  isFreeApplication,
} from "./application_status.ts";

// ─── classifyApplicationStatus ─────────────────────────────────────────────────

Deno.test("classifyApplicationStatus — paid 3종 (paid/pending_review/approved) → isPaid", () => {
  for (const s of ["paid", "pending_review", "approved"]) {
    const c = classifyApplicationStatus(s);
    assertEquals(c.isPaid, true, `${s} must be isPaid`);
    assertEquals(c.isPrePayment, false);
    assertEquals(c.isFinal, false);
  }
});

Deno.test("classifyApplicationStatus — pre-payment 2종 (pending/payment_failed) → isPrePayment", () => {
  for (const s of ["pending", "payment_failed"]) {
    const c = classifyApplicationStatus(s);
    assertEquals(c.isPrePayment, true, `${s} must be isPrePayment`);
    assertEquals(c.isPaid, false);
    assertEquals(c.isFinal, false);
  }
});

Deno.test("classifyApplicationStatus — final 2종 (cancelled/rejected) → isFinal", () => {
  for (const s of ["cancelled", "rejected"]) {
    const c = classifyApplicationStatus(s);
    assertEquals(c.isFinal, true, `${s} must be isFinal`);
    assertEquals(c.isPaid, false);
    assertEquals(c.isPrePayment, false);
  }
});

Deno.test("classifyApplicationStatus — unknown status → all false (safe default)", () => {
  const c = classifyApplicationStatus("xyz_unknown");
  assertEquals(c.isPaid, false);
  assertEquals(c.isPrePayment, false);
  assertEquals(c.isFinal, false);
});

// 카테고리 mutually exclusive 회귀 가드
Deno.test("classifyApplicationStatus — known status 들이 categories 간 상호 배타", () => {
  for (const s of [
    "pending", "payment_failed",
    "paid", "pending_review", "approved",
    "cancelled", "rejected",
  ]) {
    const c = classifyApplicationStatus(s);
    const trueCount = [c.isPaid, c.isPrePayment, c.isFinal].filter(Boolean).length;
    assertEquals(trueCount, 1, `${s} must belong to exactly one category, got ${trueCount}`);
  }
});

// ─── isFreeApplication ─────────────────────────────────────────────────────────

Deno.test("isFreeApplication — 0 → true, 양수 → false, null → false", () => {
  assertEquals(isFreeApplication(0), true);
  assertEquals(isFreeApplication(15000), false);
  assertEquals(isFreeApplication(null), false);   // damaged data, not free
});

// ─── isEventStarted ────────────────────────────────────────────────────────────

Deno.test("isEventStarted — 과거 → true, 미래 → false, 정확히 동일 → true (boundary)", () => {
  const now = new Date("2026-01-01T12:00:00Z");
  assertEquals(isEventStarted(new Date("2025-12-31T23:59:59Z"), now), true);
  assertEquals(isEventStarted(new Date("2026-01-01T12:00:01Z"), now), false);
  assertEquals(isEventStarted(now, now), true);  // boundary: 동일 시각 = 시작됨
});

Deno.test("isEventStarted — string ISO 도 동일 동작", () => {
  const now = new Date("2026-01-01T12:00:00Z");
  assertEquals(isEventStarted("2025-12-31T23:59:59Z", now), true);
  assertEquals(isEventStarted("2026-01-01T12:00:01Z", now), false);
});
