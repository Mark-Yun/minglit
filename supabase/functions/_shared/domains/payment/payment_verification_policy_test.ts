import { assertEquals } from "@std/assert";
import {
  evaluateGatewayPayment,
  isOrderOwner,
  isPaymentVerifyAlreadyProcessed,
  paidAtToIso,
} from "./payment_verification_policy.ts";

Deno.test("isPaymentVerifyAlreadyProcessed — approved/paid are idempotent success", () => {
  assertEquals(isPaymentVerifyAlreadyProcessed("approved"), true);
  assertEquals(isPaymentVerifyAlreadyProcessed("paid"), true);
  for (
    const status of ["pending", "payment_failed", "pending_review", "rejected"]
  ) {
    assertEquals(isPaymentVerifyAlreadyProcessed(status), false);
  }
});

Deno.test("isOrderOwner — authenticated user must match application owner", () => {
  assertEquals(isOrderOwner({ user_id: "u-1" }, "u-1"), true);
  assertEquals(isOrderOwner({ user_id: "u-2" }, "u-1"), false);
});

Deno.test("evaluateGatewayPayment — non-paid status rejects", () => {
  assertEquals(
    evaluateGatewayPayment({ status: "ready", amount: 10000 }, 10000),
    {
      ok: false,
      status: 400,
      message: "Payment not completed",
      reason: "payment_not_completed",
      details: { status: "ready" },
    },
  );
});

Deno.test("evaluateGatewayPayment — amount mismatch rejects with expected/actual", () => {
  assertEquals(evaluateGatewayPayment({ status: "paid", amount: 999 }, 10000), {
    ok: false,
    status: 400,
    message: "Amount mismatch",
    reason: "amount_mismatch",
    details: { expected: 10000, actual: 999 },
  });
});

Deno.test("evaluateGatewayPayment — paid and exact amount passes", () => {
  assertEquals(
    evaluateGatewayPayment({ status: "paid", amount: 10000 }, 10000),
    {
      ok: true,
    },
  );
});

Deno.test("paidAtToIso — epoch seconds convert to ISO, missing values stay null", () => {
  assertEquals(paidAtToIso(1700000000), "2023-11-14T22:13:20Z");
  assertEquals(paidAtToIso(null), null);
  assertEquals(paidAtToIso(0), null);
  assertEquals(paidAtToIso(undefined), null);
});
