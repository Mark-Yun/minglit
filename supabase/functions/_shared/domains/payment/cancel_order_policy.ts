import {
  classifyApplicationStatus,
  isFreeApplication,
} from "./application_status.ts";
import { isEventStarted } from "../event/availability.ts";

export type CancelOrderPath =
  | { ok: true; type: "pre_payment" }
  | { ok: true; type: "free" }
  | { ok: true; type: "paid_refund"; amount: number }
  | { ok: false; status: number; message: string; details?: unknown };

export interface CancelOrderApplicationSnapshot {
  status: string;
  payment_amount: number | null;
  refund_status?: string | null;
}

export function decideCancelOrderPath(
  application: CancelOrderApplicationSnapshot,
): CancelOrderPath {
  const { isPaid, isPrePayment, isFinal } = classifyApplicationStatus(
    application.status,
  );

  if (isFinal) {
    return reject(400, "이미 취소/거절된 신청입니다");
  }

  if (isPrePayment) {
    return { ok: true, type: "pre_payment" };
  }

  if (!isPaid) {
    return reject(400, "지원하지 않는 신청 상태입니다");
  }

  if (application.payment_amount === null) {
    return reject(400, "결제 정보가 손상된 신청입니다");
  }

  if (isFreeApplication(application.payment_amount)) {
    return { ok: true, type: "free" };
  }

  if (application.refund_status !== "none") {
    return reject(400, "already_refunded", {
      reason: "Refund already processed",
    });
  }

  return {
    ok: true,
    type: "paid_refund",
    amount: application.payment_amount,
  };
}

export function evaluateFreeCancellationWindow(
  eventStartTime: string | Date,
  now: Date,
): CancelOrderPath {
  if (isEventStarted(eventStartTime, now)) {
    return reject(400, "refund_not_eligible", {
      reason: "event_already_started",
    });
  }
  return { ok: true, type: "free" };
}

function reject(
  status: number,
  message: string,
  details?: unknown,
): CancelOrderPath {
  if (details === undefined) return { ok: false, status, message };
  return { ok: false, status, message, details };
}
