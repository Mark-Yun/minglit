// _shared/domains/event/availability_test.ts
// pure unit tests — mock 0, IO 0

import { assertEquals } from "jsr:@std/assert@1";
import {
  isEventEditableByPartner,
  isEventFull,
  isEventOpenForApplication,
  isEventStarted,
  isTicketSoldOut,
} from "./availability.ts";

// ─── isEventOpenForApplication ─────────────────────────────────────────────────

Deno.test("isEventOpenForApplication — scheduled / active → true, 나머지 → false", () => {
  assertEquals(isEventOpenForApplication("scheduled"), true);
  assertEquals(isEventOpenForApplication("active"), true);
  for (const s of ["closed", "cancelled", "draft", "ended", "xyz"]) {
    assertEquals(isEventOpenForApplication(s), false, `${s} must be closed for application`);
  }
});

// ─── isEventEditableByPartner ──────────────────────────────────────────────────

Deno.test("isEventEditableByPartner — scheduled 만 true (state machine 가드)", () => {
  assertEquals(isEventEditableByPartner("scheduled"), true);
  for (const s of ["active", "closed", "cancelled", "draft", "ended"]) {
    assertEquals(isEventEditableByPartner(s), false, `${s} must NOT be editable`);
  }
});

// 두 predicate 의 의미 차이 회귀 가드 — active 가 갈리는 지점
Deno.test("isEventOpenForApplication / isEventEditableByPartner — active 에서 갈림", () => {
  assertEquals(isEventOpenForApplication("active"), true);
  assertEquals(isEventEditableByPartner("active"), false);
});

// ─── isEventFull ───────────────────────────────────────────────────────────────

Deno.test("isEventFull — current >= max → true (boundary 포함)", () => {
  assertEquals(isEventFull(9, 10), false);
  assertEquals(isEventFull(10, 10), true);   // boundary: 정확히 가득
  assertEquals(isEventFull(11, 10), true);   // overflow (방어적)
  assertEquals(isEventFull(0, 0), true);     // 한도 0 (즉시 fully booked)
});

// ─── isTicketSoldOut ───────────────────────────────────────────────────────────

Deno.test("isTicketSoldOut — sold_count >= quantity → true (boundary 포함)", () => {
  assertEquals(isTicketSoldOut(99, 100), false);
  assertEquals(isTicketSoldOut(100, 100), true);
  assertEquals(isTicketSoldOut(101, 100), true);
  assertEquals(isTicketSoldOut(0, 0), true);
});

// ─── isEventStarted ────────────────────────────────────────────────────────────

Deno.test("isEventStarted — 과거 → true, 미래 → false, 정확히 동일 → true (boundary)", () => {
  const now = new Date("2026-01-01T12:00:00Z");
  assertEquals(isEventStarted(new Date("2025-12-31T23:59:59Z"), now), true);
  assertEquals(isEventStarted(new Date("2026-01-01T12:00:01Z"), now), false);
  assertEquals(isEventStarted(now, now), true);
});

Deno.test("isEventStarted — string ISO 도 동일 동작", () => {
  const now = new Date("2026-01-01T12:00:00Z");
  assertEquals(isEventStarted("2025-12-31T23:59:59Z", now), true);
  assertEquals(isEventStarted("2026-01-01T12:00:01Z", now), false);
});
