/**
 * 상태 칩 어휘 SSoT — MDS 웹 spec 의 어휘 표를 코드로 옮긴 단일 매핑.
 *
 * 출처:
 * - 유저 구매 칩 6종: apps/mds/docs/public/specs/web_user_purchases/index.html
 *   "StatusChip 어휘 — 목록·상세 공용" 표
 * - 파트너 신청 탭 3종: apps/mds/docs/public/specs/web_partner_applications/index.html
 *   ApplicationListPanel 상태 필터 (대기 N / 확정 N / 거절 N)
 *
 * DB 어휘 (event_applications.status check 제약 —
 * migrations/20260301000004_04_schema_commerce.sql):
 * pending · pending_review · approved · rejected · cancelled · paid ·
 * payment_failed · payment_pending / refund_status: none · requested · completed
 */

export type StatusTone = "success" | "warning" | "error" | "info" | "neutral";

export interface StatusChipSpec {
  label: string;
  tone: StatusTone;
}

/** event_applications.status (DB check 제약 그대로) */
export type ApplicationStatus =
  | "pending"
  | "pending_review"
  | "approved"
  | "rejected"
  | "cancelled"
  | "paid"
  | "payment_failed"
  | "payment_pending";

/** event_applications.refund_status */
export type RefundStatus = "none" | "requested" | "completed";

// ── 유저 구매 내역 칩 (web_user_purchases — 한 건당 칩 1개) ──

export type PurchaseStatusKey =
  | "awaiting_approval"
  | "confirmed"
  | "refund_in_progress"
  | "refunded"
  | "rejected_refunded"
  | "event_ended";

export const PURCHASE_STATUS_CHIPS: Record<PurchaseStatusKey, StatusChipSpec> =
  {
    /** 결제는 끝났고 파트너가 신청을 검토 중 */
    awaiting_approval: { label: "승인 대기", tone: "warning" },
    /** 참가 확정 (결제 완료 또는 승인 완료) + 이벤트 시작 전 */
    confirmed: { label: "확정", tone: "success" },
    /** 환불 요청 접수 — 처리(입금) 대기 */
    refund_in_progress: { label: "환불 요청 중", tone: "info" },
    /** 본인 요청 환불 완료 (파트너 이벤트 취소 환불 포함 — 상세 타임라인으로 구분) */
    refunded: { label: "환불됨", tone: "neutral" },
    /** 파트너 거절 → 전액 자동 환불 완료 */
    rejected_refunded: { label: "거절·환불됨", tone: "error" },
    /** 이벤트 일시가 지났고 정상 참가로 종결 */
    event_ended: { label: "이벤트 종료", tone: "neutral" },
  };

/**
 * application 상태 → 구매 칩 key 매핑.
 * spec note: 결제 미성립 건(payment_pending/payment_failed)은 목록 비노출 → null.
 *
 * TODO(web-kit): 거절 직후 자동 환불이 아직 처리 중(refund_status=requested)인
 * 짧은 구간의 칩 — spec 은 "거절·환불됨" 단일 칩으로 합성하므로 rejected 우선으로
 * 두었다. 구현 화면에서 spec 검수 시 확정할 것.
 */
export function resolvePurchaseStatusKey(input: {
  status: ApplicationStatus;
  refundStatus: RefundStatus;
  /** 이벤트 일시(종료 시각)가 지났는지 — 호출부에서 KST 기준 판정 */
  eventEnded: boolean;
}): PurchaseStatusKey | null {
  const { status, refundStatus, eventEnded } = input;

  if (status === "payment_pending" || status === "payment_failed") return null;
  if (status === "rejected") return "rejected_refunded";
  if (refundStatus === "completed") return "refunded";
  if (refundStatus === "requested") return "refund_in_progress";
  if (status === "cancelled") return "refunded";
  if (eventEnded) return "event_ended";
  if (status === "pending" || status === "pending_review") {
    return "awaiting_approval";
  }
  // approved | paid
  return "confirmed";
}

// ── 파트너 신청 관리 탭 (web_partner_applications — 대기/확정/거절) ──

export type PartnerApplicationTabKey = "pending" | "confirmed" | "rejected";

export interface PartnerApplicationTabSpec {
  label: string;
  /** 이 탭이 포함하는 application 상태 */
  statuses: readonly ApplicationStatus[];
}

export const PARTNER_APPLICATION_TABS: Record<
  PartnerApplicationTabKey,
  PartnerApplicationTabSpec
> = {
  /** 정렬: 오래된 신청 순 (먼저 온 사람 먼저 처리) */
  pending: { label: "대기", statuses: ["pending", "pending_review"] },
  /** 정렬: 최근 처리 순 */
  confirmed: { label: "확정", statuses: ["approved", "paid"] },
  /** 정렬: 최근 처리 순 · read-only (거절 사유 + 환불 상태 행 추가) */
  rejected: { label: "거절", statuses: ["rejected"] },
};

/** URL query param 순서 고정 (spec: /applications?event=…&tab=…&mode=…) */
export const PARTNER_APPLICATION_TAB_ORDER: readonly PartnerApplicationTabKey[] =
  ["pending", "confirmed", "rejected"];
