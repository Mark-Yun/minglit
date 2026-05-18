// _shared/domains/payment/refund_policy.ts — 환불 정책 (pure)
//
// 환불 가능 여부 판단:
//   - grace period: 결제 직후 N시간 내 자유 환불
//   - cutoff: 이벤트 시작 D일 전까지 환불 가능
//   - 이벤트 시작 후 → 항상 불가 (Fix #1235)
//
// 둘 중 하나라도 만족하면 eligible.

/** 정책 RPC 가 반환하는 raw record 가 깨졌을 때 사용할 기본값 */
const DEFAULT_GRACE_PERIOD_HOURS = 2;
const DEFAULT_CUTOFF_DAYS = 7;

export interface RefundPolicy {
  gracePeriodHours: number;
  cutoffDays: number;
}

/**
 * `get_current_policy('refund')` RPC 결과를 typed 정책으로 변환.
 * 누락 / 깨진 값은 안전한 기본값 (2시간 grace, 7일 cutoff) 으로 폴백.
 *
 * 두 EF (user-cancel-order / payment-cancel) 가 동일한 default 를 따로 두던 것을 통합.
 */
export function parseRefundPolicy(raw: unknown): RefundPolicy {
  const record = (raw && typeof raw === "object") ? raw as Record<string, unknown> : {};
  const grace = record.grace_period_hours;
  const cutoff = record.cutoff_days;
  return {
    gracePeriodHours: typeof grace === "number" && grace >= 0 ? grace : DEFAULT_GRACE_PERIOD_HOURS,
    cutoffDays: typeof cutoff === "number" && cutoff >= 0 ? cutoff : DEFAULT_CUTOFF_DAYS,
  };
}

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
