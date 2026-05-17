// _shared/domains/payment/application_status_test.ts
// pure unit tests — mock 0, IO 0, ms 단위로 통과

import { assertEquals } from "jsr:@std/assert@1";
import {
  blocksReapplication,
  classifyApplicationStatus,
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

// ─── blocksReapplication ───────────────────────────────────────────────────────

Deno.test("blocksReapplication — cancelled / payment_failed → false (재신청 허용)", () => {
  assertEquals(blocksReapplication("cancelled"), false);
  assertEquals(blocksReapplication("payment_failed"), false);
});

Deno.test("blocksReapplication — pending / paid / pending_review / approved / rejected → true (차단)", () => {
  for (const s of ["pending", "paid", "pending_review", "approved", "rejected"]) {
    assertEquals(blocksReapplication(s), true, `${s} must block reapplication`);
  }
});

// isEventStarted → moved to `_shared/domains/event/availability.ts`
