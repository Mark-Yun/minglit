import { IamportClient } from "./iamport_client.ts";
import { log } from "./logger.ts";

/**
 * Shared refund utilities for user-cancel-order and payment-cancel.
 *
 * Extracted per #299 to avoid duplicating eligibility logic and PortOne calls.
 */

export interface RefundEligibilityParams {
  paidAt: string | null;
  eventStartTime: string;
  gracePeriodHours: number;
  cutoffDays: number;
  now?: Date;
}

export interface RefundEligibilityResult {
  eligible: boolean;
  reason?: string;
}

/**
 * Verify whether a refund is eligible based on grace period and cutoff policy.
 *
 * Eligible if EITHER:
 * - Within grace period (paidAt is past and within gracePeriodHours), OR
 * - Within cutoff (event starts >= cutoffDays from now)
 */
export function verifyRefundEligibility(
  params: RefundEligibilityParams,
): RefundEligibilityResult {
  const now = params.now ?? new Date();
  const paidAt = params.paidAt ? new Date(params.paidAt) : null;
  const eventStart = new Date(params.eventStartTime);

  // Fix #133: 미래 paid_at은 음수 duration으로 grace period를 통과하므로 명시적으로 제외
  const withinGracePeriod =
    paidAt !== null &&
    paidAt.getTime() <= now.getTime() &&
    now.getTime() - paidAt.getTime() <=
      params.gracePeriodHours * 60 * 60 * 1000;

  const withinCutoff =
    eventStart.getTime() - now.getTime() >=
      params.cutoffDays * 24 * 60 * 60 * 1000;

  if (!withinGracePeriod && !withinCutoff) {
    return { eligible: false, reason: "Refund window has expired" };
  }

  return { eligible: true };
}

export interface ExecuteRefundParams {
  paymentId: string;
  reason: string;
  amount?: number;
  checksum?: number;
  fnName: string;
}

/**
 * Execute a refund via PortOne (Iamport) API.
 *
 * Returns the cancel response on success, or throws on failure.
 */
export async function executeRefund(
  params: ExecuteRefundParams,
): Promise<Record<string, unknown>> {
  const impKey = Deno.env.get("PORTONE_API_KEY");
  const impSecret = Deno.env.get("PORTONE_API_SECRET");

  if (!impKey || !impSecret) {
    log({ function: params.fnName, level: "error", message: "Missing Portone credentials" });
    throw new RefundError("Server configuration error", 500);
  }

  const client = new IamportClient(impKey, impSecret);
  try {
    return await client.cancelPayment(
      params.paymentId,
      params.reason,
      params.amount,
      params.checksum,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    log({ function: params.fnName, level: "error", message: `Failed to cancel payment: ${message}` });
    if (message.startsWith("Failed to get token") || message.startsWith("Iamport Error")) {
      throw new RefundError("Payment provider error", 502);
    }
    throw new RefundError(message, 400);
  }
}

/**
 * Typed error for refund operations, carrying an HTTP status code.
 */
export class RefundError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "RefundError";
    this.status = status;
  }
}
