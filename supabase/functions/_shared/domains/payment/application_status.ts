// _shared/domains/payment/application_status.ts — application status 분류 (pure)
//
// event_applications.status 의 값 종류:
//   pending          — 신청 직후, 결제 안 됨
//   payment_failed   — 결제 시도 실패
//   pending_review   — 결제 완료, 파트너 심사 대기
//   approved         — 파트너 승인 (paid 의 한 형태)
//   paid             — 결제 완료 + 자동 승인 (free + verification 없음 등, Fix #1660)
//   cancelled        — 유저 취소
//   rejected         — 파트너 거절
//
// 각 EF 가 이 분류를 중복 구현하던 것을 한 곳으로 모음.

export type ApplicationStatus =
  | "pending"
  | "payment_failed"
  | "pending_review"
  | "approved"
  | "paid"
  | "cancelled"
  | "rejected";

export interface StatusClassification {
  /** 결제 완료 상태 (환불 대상) */
  isPaid: boolean;
  /** 결제 전 상태 (즉시 삭제 가능) */
  isPrePayment: boolean;
  /** 종결 상태 (추가 변경 불가) */
  isFinal: boolean;
}

const PAID_STATES: readonly ApplicationStatus[] = ["paid", "pending_review", "approved"];
const PRE_PAYMENT_STATES: readonly ApplicationStatus[] = ["pending", "payment_failed"];
const FINAL_STATES: readonly ApplicationStatus[] = ["cancelled", "rejected"];

/**
 * application.status 를 EF 행위 분기용 boolean 으로 분류.
 * 한 status 는 정확히 하나의 카테고리 (PAID / PRE_PAYMENT / FINAL) 에 속함.
 */
export function classifyApplicationStatus(status: string): StatusClassification {
  const typed = status as ApplicationStatus;
  return {
    isPaid: PAID_STATES.includes(typed),
    isPrePayment: PRE_PAYMENT_STATES.includes(typed),
    isFinal: FINAL_STATES.includes(typed),
  };
}

/** payment_amount=0 → 무료 이벤트 */
export function isFreeApplication(paymentAmount: number | null): boolean {
  return paymentAmount === 0;
}

/**
 * 동일 (event, user) 에 이미 application 이 있을 때, **재신청을 차단해야 하는가**.
 *
 * cancelled / payment_failed 만 재신청 허용. 그 외 (pending / paid / approved /
 * pending_review / rejected) 는 자리 차지 중 → 재신청 거절.
 *
 * user-create-order, apply-event 의 중복 신청 가드 공용.
 */
export function blocksReapplication(status: string): boolean {
  return status !== "cancelled" && status !== "payment_failed";
}
