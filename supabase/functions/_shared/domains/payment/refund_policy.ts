// _shared/domains/payment/refund_policy.ts — 환불 정책 (pure)
//
// 환불 가능 여부 판단:
//   - grace period: 결제 직후 N시간 내 자유 환불
//   - cutoff: 이벤트 시작 D일 전까지 환불 가능
//   - 이벤트 시작 후 → 항상 불가 (Fix #1235)
//
// 둘 중 하나라도 만족하면 eligible.

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
 * 환불 가능 여부 — grace period OR cutoff 둘 중 하나 만족 시 eligible.
 * 이벤트 시작 후에는 항상 불가 (Fix #1235).
 */
export function verifyRefundEligibility(
  params: RefundEligibilityParams,
): RefundEligibilityResult {
  const now = params.now ?? new Date();
  const paidAt = params.paidAt ? new Date(params.paidAt) : null;
  const eventStart = new Date(params.eventStartTime);

  // Fix #1235: 이벤트 시작 후 예매 취소 요청 차단
  if (eventStart.getTime() <= now.getTime()) {
    return { eligible: false, reason: "Event has already started" };
  }

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
