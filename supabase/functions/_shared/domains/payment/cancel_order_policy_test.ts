import { assertEquals } from "@std/assert";
import {
  decideCancelOrderPath,
  evaluateFreeCancellationWindow,
} from "./cancel_order_policy.ts";

Deno.test("decideCancelOrderPath — final statuses reject", () => {
  for (const status of ["cancelled", "rejected"]) {
    assertEquals(
      decideCancelOrderPath({
        status,
        payment_amount: 30000,
        refund_status: "none",
      }),
      { ok: false, status: 400, message: "이미 취소/거절된 신청입니다" },
    );
  }
});

Deno.test("decideCancelOrderPath — pre-payment statuses delete application", () => {
  assertEquals(
    decideCancelOrderPath({
      status: "pending",
      payment_amount: 30000,
      refund_status: "none",
    }),
    { ok: true, type: "pre_payment" },
  );
  assertEquals(
    decideCancelOrderPath({
      status: "payment_failed",
      payment_amount: 30000,
      refund_status: "none",
    }),
    { ok: true, type: "pre_payment" },
  );
});

Deno.test("decideCancelOrderPath — paid with null amount rejects damaged data", () => {
  assertEquals(
    decideCancelOrderPath({
      status: "paid",
      payment_amount: null,
      refund_status: "none",
    }),
    { ok: false, status: 400, message: "결제 정보가 손상된 신청입니다" },
  );
});

Deno.test("decideCancelOrderPath — free paid application uses free cancel path", () => {
  assertEquals(
    decideCancelOrderPath({
      status: "paid",
      payment_amount: 0,
      refund_status: "none",
    }),
    { ok: true, type: "free" },
  );
});

Deno.test("decideCancelOrderPath — paid refund rejects already refunded", () => {
  assertEquals(
    decideCancelOrderPath({
      status: "paid",
      payment_amount: 30000,
      refund_status: "completed",
    }),
    {
      ok: false,
      status: 400,
      message: "already_refunded",
      details: { reason: "Refund already processed" },
    },
  );
});

Deno.test("decideCancelOrderPath — paid/pending_review/approved require refund", () => {
  for (const status of ["paid", "pending_review", "approved"]) {
    assertEquals(
      decideCancelOrderPath({
        status,
        payment_amount: 30000,
        refund_status: "none",
      }),
      { ok: true, type: "paid_refund", amount: 30000 },
    );
  }
});

Deno.test("evaluateFreeCancellationWindow — event already started rejects", () => {
  const now = new Date("2026-01-01T12:00:00Z");
  assertEquals(evaluateFreeCancellationWindow(now, now), {
    ok: false,
    status: 400,
    message: "refund_not_eligible",
    details: { reason: "event_already_started" },
  });
});

Deno.test("evaluateFreeCancellationWindow — future event passes", () => {
  const now = new Date("2026-01-01T12:00:00Z");
  assertEquals(
    evaluateFreeCancellationWindow("2026-01-01T12:00:01Z", now),
    { ok: true, type: "free" },
  );
});
