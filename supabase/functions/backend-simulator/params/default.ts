// v2/params/default.ts — 확률 파라미터 (production-like)
//
// 철학:
// - Happy path (apply→pay→checkin) 위주 (0.85-0.95)
// - Critical negative (refund/block/reject) slight (0.05-0.15) — 매 cascade 에 sampling 보장
// - 절대값보다 운영 데이터 fit 방향 우선
// 상세: ../../architecture.md Part 2 확률 파라미터 철학

export interface Rates {
  user: Record<string, number>;
  partner: Record<string, number>;
}

export const defaultRates: Rates = {
  user: {
    user_apply: 0.85,         // 본 visible event 중 신청 비율
    user_pay: 0.95,           // 신청 후 결제 완료
    user_refund: 0.10,        // 결제 후 환불 (critical — 본 PoC 가드 대상)
    user_checkin: 0.85,       // active event 체크인
    user_vote: 0.60,          // ongoing event 투표
    user_block: 0.05,         // 임의 시점 partner block (critical — cross-EF 가드)
  },
  partner: {
    partner_approve: 0.85,    // pending_review 승인
    partner_reject: 0.15,     // pending_review 거절
    partner_create_event: 0.30,  // 임계치 미달 시 신규 이벤트
  },
};
