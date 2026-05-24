export type PaymentVerificationReason =
  | "payment_not_completed"
  | "amount_mismatch";

export type PaymentVerificationResult =
  | { ok: true }
  | {
    ok: false;
    status: number;
    message: string;
    reason: PaymentVerificationReason;
    details: Record<string, unknown>;
  };

export interface PaymentVerificationOrderSnapshot {
  payment_amount: number;
  status: string;
  user_id: string;
}

export interface PaymentGatewaySnapshot {
  status: string;
  amount: number;
  paid_at?: number | null;
}

export function isPaymentVerifyAlreadyProcessed(status: string): boolean {
  return status === "approved" || status === "paid";
}

export function isOrderOwner(
  order: Pick<PaymentVerificationOrderSnapshot, "user_id">,
  userId: string,
): boolean {
  return order.user_id === userId;
}

export function evaluateGatewayPayment(
  payment: PaymentGatewaySnapshot,
  expectedAmount: number,
): PaymentVerificationResult {
  if (payment.status !== "paid") {
    return {
      ok: false,
      status: 400,
      message: "Payment not completed",
      reason: "payment_not_completed",
      details: { status: payment.status },
    };
  }

  if (payment.amount !== expectedAmount) {
    return {
      ok: false,
      status: 400,
      message: "Amount mismatch",
      reason: "amount_mismatch",
      details: { expected: expectedAmount, actual: payment.amount },
    };
  }

  return { ok: true };
}

export function paidAtToIso(paidAt: number | null | undefined): string | null {
  if (!paidAt || paidAt <= 0) return null;
  return new Date(paidAt * 1000).toISOString().replace(".000Z", "Z");
}
