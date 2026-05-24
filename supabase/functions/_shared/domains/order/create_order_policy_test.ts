import { assertEquals } from "@std/assert";
import {
  type CreateOrderEntryGroupSnapshot,
  type CreateOrderEventSnapshot,
  type CreateOrderTicketSnapshot,
  type CreateOrderUserProfileSnapshot,
  decideCreateOrderPaymentPlan,
  evaluateEntryGroupEligibility,
  evaluateEventAvailability,
  evaluateEventCapacity,
  evaluateIdentity,
  evaluatePartyBalance,
  evaluateReapplication,
  evaluateTicketAvailability,
} from "./create_order_policy.ts";

const NOW = new Date("2026-01-01T12:00:00Z");

function event(
  overrides: Partial<CreateOrderEventSnapshot> = {},
): CreateOrderEventSnapshot {
  return {
    status: "scheduled",
    start_time: "2026-01-02T12:00:00Z",
    max_participants: 20,
    current_participants: 5,
    ...overrides,
  };
}

function ticket(
  overrides: Partial<CreateOrderTicketSnapshot> = {},
): CreateOrderTicketSnapshot {
  return {
    event_id: "ev-1",
    price: 15000,
    quantity: 10,
    sold_count: 3,
    ...overrides,
  };
}

function profile(
  overrides: Partial<CreateOrderUserProfileSnapshot> = {},
): CreateOrderUserProfileSnapshot {
  return {
    is_verified: true,
    gender: "male",
    birth_date: "1995-06-15",
    ...overrides,
  };
}

function group(
  overrides: Partial<CreateOrderEntryGroupSnapshot> = {},
): CreateOrderEntryGroupSnapshot {
  return {
    gender: "male",
    birth_year_min: 1990,
    birth_year_max: 2000,
    required_verification_ids: [],
    ...overrides,
  };
}

Deno.test("evaluateEventAvailability — closed status rejects", () => {
  const result = evaluateEventAvailability(event({ status: "cancelled" }), NOW);
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "이벤트가 마감되었습니다.",
    code: "EVENT_CLOSED",
  });
});

Deno.test("evaluateEventAvailability — already started rejects", () => {
  const result = evaluateEventAvailability(event({ start_time: NOW }), NOW);
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "이벤트가 마감되었습니다.",
    code: "EVENT_NOT_SCHEDULED",
  });
});

Deno.test("evaluateEventAvailability — full event rejects", () => {
  const result = evaluateEventAvailability(
    event({ current_participants: 20, max_participants: 20 }),
    NOW,
  );
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "정원이 초과되었습니다.",
    code: "EVENT_FULL",
  });
});

Deno.test("evaluateEventCapacity — capacity check can run after ticket validation", () => {
  const result = evaluateEventCapacity(
    event({ current_participants: 20, max_participants: 20 }),
  );
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "정원이 초과되었습니다.",
    code: "EVENT_FULL",
  });
});

Deno.test("evaluateTicketAvailability — ticket from different event maps to 404", () => {
  const result = evaluateTicketAvailability(
    ticket({ event_id: "ev-other" }),
    "ev-1",
  );
  assertEquals(result, {
    ok: false,
    status: 404,
    message: "티켓을 찾을 수 없습니다.",
  });
});

Deno.test("evaluateTicketAvailability — sold out rejects", () => {
  const result = evaluateTicketAvailability(
    ticket({ sold_count: 10, quantity: 10 }),
    "ev-1",
  );
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "티켓이 매진되었습니다.",
    code: "TICKET_SOLD_OUT",
  });
});

Deno.test("evaluateIdentity — unverified user rejects", () => {
  const result = evaluateIdentity(profile({ is_verified: false }));
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "본인인증이 필요합니다.",
    code: "IDENTITY_REQUIRED",
  });
});

Deno.test("evaluateEntryGroupEligibility — gender mismatch rejects", () => {
  const result = evaluateEntryGroupEligibility({
    profile: profile({ gender: "female" }),
    entryGroups: [group({ gender: "male" })],
  });
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "성별 조건이 맞지 않습니다.",
    code: "GENDER_MISMATCH",
  });
});

Deno.test("evaluateEntryGroupEligibility — birth year min/max rejects", () => {
  assertEquals(
    evaluateEntryGroupEligibility({
      profile: profile({ birth_date: "1989-01-01" }),
      entryGroups: [group({ birth_year_min: 1990 })],
    }),
    {
      ok: false,
      status: 400,
      message: "나이 조건이 맞지 않습니다.",
      code: "AGE_MISMATCH",
    },
  );
  assertEquals(
    evaluateEntryGroupEligibility({
      profile: profile({ birth_date: "2001-01-01" }),
      entryGroups: [group({ birth_year_max: 2000 })],
    }),
    {
      ok: false,
      status: 400,
      message: "나이 조건이 맞지 않습니다.",
      code: "AGE_MISMATCH",
    },
  );
});

Deno.test("evaluateEntryGroupEligibility — required verification rejects missing verification data", () => {
  const result = evaluateEntryGroupEligibility({
    profile: profile(),
    entryGroups: [group({ required_verification_ids: ["student-id"] })],
  });
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "자격 인증 정보가 필요합니다.",
    code: "VERIFICATION_REQUIRED",
  });
});

Deno.test("evaluatePartyBalance — allowed=false rejects", () => {
  const result = evaluatePartyBalance({ allowed: false });
  assertEquals(result, {
    ok: false,
    status: 400,
    message: "성비 균형 제한입니다.",
    code: "BALANCE_LIMIT",
  });
});

Deno.test("evaluateReapplication — cancelled/payment_failed allowed, paid blocked", () => {
  assertEquals(evaluateReapplication({ status: "cancelled" }), { ok: true });
  assertEquals(evaluateReapplication({ status: "payment_failed" }), {
    ok: true,
  });
  assertEquals(evaluateReapplication({ status: "paid" }), {
    ok: false,
    status: 400,
    message: "이미 신청한 이벤트입니다.",
    code: "ALREADY_APPLIED",
  });
});

Deno.test("decideCreateOrderPaymentPlan — paid ticket pending, free ticket paid", () => {
  assertEquals(decideCreateOrderPaymentPlan(ticket({ price: 15000 })), {
    amount: 15000,
    requiresPayment: true,
    initialStatus: "pending",
  });
  assertEquals(decideCreateOrderPaymentPlan(ticket({ price: 0 })), {
    amount: 0,
    requiresPayment: false,
    initialStatus: "paid",
  });
});
