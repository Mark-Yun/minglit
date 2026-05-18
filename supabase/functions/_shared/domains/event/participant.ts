// _shared/domains/event/participant.ts — event_participants 분류 (pure)
//
// event_participants.status 의 값:
//   ticket_issued — 티켓 발급, 체크인 대기
//   checked_in    — 현장 체크인 완료. 매칭/투표 자격
//   no_show       — 미참석 (이벤트 종료 후)
//
// 매칭 / 투표 EF 들이 "checked_in 자격 가드" 를 인라인으로 따로 두던 것을 통합.

/** 현장 체크인 완료 — 매칭/투표 등 활동 자격 가드 */
export function isCheckedIn(status: string): boolean {
  return status === "checked_in";
}
