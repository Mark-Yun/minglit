// _shared/domains/event/availability.ts — 이벤트 신청/편집 가능 여부 (pure)
//
// events.status 의 의미적 분류:
//   scheduled — 신청 + 편집 가능 (정상 상태)
//   active    — 이벤트 진행 중. 신청 가능, 편집 불가 (state machine)
//   cancelled / closed — 종결
//
// 두 predicate 의 의미 차이:
//   - isEventOpenForApplication: 유저가 신청 시도 가능한가 → scheduled OR active (Fix #998)
//   - isEventEditableByPartner: 파트너가 상태/규칙 변경 가능한가 → scheduled 만 (state machine 가드)

export interface EventLike {
  status: string;
}

/** 유저 신청 가능 여부 (Fix #998: active 도 허용) */
export function isEventOpenForApplication(status: string): boolean {
  return status === "scheduled" || status === "active";
}

/** 파트너 편집 (취소, 매칭 규칙 변경 등) 가능 여부 — state machine 가드 */
export function isEventEditableByPartner(status: string): boolean {
  return status === "scheduled";
}

/** 정원 초과 여부 */
export function isEventFull(currentParticipants: number, maxParticipants: number): boolean {
  return currentParticipants >= maxParticipants;
}

/** 티켓 매진 여부 */
export function isTicketSoldOut(soldCount: number, quantity: number): boolean {
  return soldCount >= quantity;
}

/** 이벤트 시작 시각 vs 기준 시각 — 시작 이후면 true (refund / 신청 / 노출 cutoff 공용) */
export function isEventStarted(startTime: string | Date, now: Date = new Date()): boolean {
  const start = typeof startTime === "string" ? new Date(startTime) : startTime;
  return start.getTime() <= now.getTime();
}
