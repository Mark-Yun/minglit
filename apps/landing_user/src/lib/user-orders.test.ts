import assert from "node:assert/strict";
import test from "node:test";

import { canRequestAutomaticRefund, checkoutGate, findCheckoutTicket, mapPurchaseRow, statusCopy } from "./user-orders";
import type { PublicEvent } from "./events";

test("findCheckoutTicket returns only orderable on-sale tickets", () => {
  const event = buildEvent();

  assert.equal(findCheckoutTicket(event, "ticket-open")?.id, "ticket-open");
  assert.equal(findCheckoutTicket(event, "ticket-sold-out"), null);
  assert.equal(findCheckoutTicket(event, "ticket-hidden"), null);
  assert.equal(findCheckoutTicket(event, null), null);
});

test("checkoutGate blocks unverified users before server order creation", () => {
  assert.deepEqual(checkoutGate({
    authStatus: "ready",
    isVerified: false,
    agreed: true,
    ticketPrice: 0,
    isCreating: false,
  }), {
    canSubmit: false,
    helper: "본인인증 후 결제할 수 있어요.",
  });
});

test("checkoutGate keeps paid tickets disabled until web payment adapter exists", () => {
  assert.deepEqual(checkoutGate({
    authStatus: "ready",
    isVerified: true,
    agreed: true,
    ticketPrice: 39000,
    isCreating: false,
  }), {
    canSubmit: false,
    helper: "유료 결제창은 아직 연결되지 않아 출시 전입니다.",
  });
});

test("checkoutGate allows verified free-ticket applications after consent", () => {
  assert.equal(checkoutGate({
    authStatus: "ready",
    isVerified: true,
    agreed: true,
    ticketPrice: 0,
    isCreating: false,
  }).canSubmit, true);
});

test("mapPurchaseRow normalizes joined event, ticket, and status fields", () => {
  const purchase = mapPurchaseRow({
    id: "app-1",
    event_id: "event-1",
    ticket_id: "ticket-1",
    status: "paid",
    payment_id: "pay-1",
    payment_amount: 39000,
    refund_status: null,
    rejection_reason: null,
    created_at: "2026-07-01T00:00:00.000Z",
    paid_at: "2026-07-01T00:30:00.000Z",
    refunded_at: null,
    events: {
      id: "event-1",
      title: null,
      start_time: "2026-07-10T10:00:00.000Z",
      end_time: "2026-07-10T12:00:00.000Z",
      image_urls: [],
      locations: { name: null, address: "서울 강남구", region_1: "서울", region_2: "강남" },
      parties: {
        title: "와인 소셜",
        image_urls: ["https://example.com/event.png"],
        partners: { name: "밍글 스튜디오" },
      },
    },
    tickets: { id: "ticket-1", name: "일반 참가권", price: 39000 },
  });

  assert.equal(purchase.eventTitle, "와인 소셜");
  assert.equal(purchase.locationName, "서울 강남");
  assert.equal(purchase.eventImageUrl, "https://example.com/event.png");
  assert.equal(purchase.status, "paid");
  assert.equal(purchase.refundStatus, "none");
});

test("statusCopy prioritizes refund state over application state", () => {
  assert.deepEqual(statusCopy("approved", "completed"), { label: "환불 완료", tone: "neutral" });
  assert.deepEqual(statusCopy("rejected", "none"), { label: "거절됨", tone: "error" });
});

test("statusCopy surfaces event-ended chip for completed-ish purchases without refunds", () => {
  assert.deepEqual(statusCopy("approved", "none", true), { label: "이벤트 종료", tone: "neutral" });
  assert.deepEqual(statusCopy("paid", "none", true), { label: "이벤트 종료", tone: "neutral" });
  // refund state still wins over event-ended.
  assert.deepEqual(statusCopy("approved", "requested", true), { label: "환불 요청됨", tone: "warning" });
  // non-completed statuses keep their own copy even after the event ends.
  assert.deepEqual(statusCopy("rejected", "none", true), { label: "거절됨", tone: "error" });
  // default (no third arg) preserves the existing two-arg behavior.
  assert.deepEqual(statusCopy("approved", "none"), { label: "확정", tone: "success" });
});

test("canRequestAutomaticRefund follows 3h grace and 7d cutoff", () => {
  const base = {
    id: "app-1",
    eventId: "event-1",
    ticketId: "ticket-1",
    eventTitle: "이벤트",
    eventImageUrl: null,
    startsAt: "2026-07-10T10:00:00.000Z",
    endsAt: "2026-07-10T12:00:00.000Z",
    locationName: "서울",
    locationAddress: "서울",
    partnerName: "파트너",
    ticketName: "티켓",
    amount: 10000,
    status: "paid" as const,
    refundStatus: "none" as const,
    rejectionReason: null,
    paymentId: "pay-1",
    createdAt: "2026-07-01T00:00:00.000Z",
    paidAt: "2026-07-01T00:00:00.000Z",
    refundedAt: null,
  };

  assert.equal(canRequestAutomaticRefund(base, new Date("2026-07-01T02:59:59.000Z")), true);
  assert.equal(canRequestAutomaticRefund(base, new Date("2026-07-03T00:00:00.000Z")), true);
  assert.equal(canRequestAutomaticRefund({ ...base, startsAt: "2026-07-05T10:00:00.000Z" }, new Date("2026-07-03T00:00:00.000Z")), false);
});

function buildEvent(): PublicEvent {
  return {
    id: "event-1",
    title: "이벤트",
    description: "설명",
    imageUrl: null,
    startsAt: "2026-07-01T10:00:00.000Z",
    endsAt: "2026-07-01T12:00:00.000Z",
    status: "scheduled",
    maxParticipants: 20,
    currentParticipants: 0,
    partnerName: "파트너",
    partnerIntro: "소개",
    locationName: "서울",
    locationAddress: "서울",
    tags: ["소셜"],
    tickets: [
      { id: "ticket-open", name: "일반", description: null, price: 10000, quantity: 10, soldCount: 1, status: "on_sale" },
      { id: "ticket-sold-out", name: "매진", description: null, price: 10000, quantity: 10, soldCount: 10, status: "on_sale" },
      { id: "ticket-hidden", name: "숨김", description: null, price: 10000, quantity: 10, soldCount: 0, status: "hidden" },
    ],
  };
}
