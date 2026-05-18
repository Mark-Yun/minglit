import { IamportClient } from "./iamport_client.ts";
import { log } from "./logger.ts";

/**
 * Shared refund IO — PortOne (Iamport) 취소 호출 + 에러 타입.
 *
 * pure 정책 (eligibility 계산) 은 `_shared/domains/payment/refund_policy.ts` 로 이동.
 * 이 파일은 IO + env access 가 필요한 부분만 보존.
 */

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
