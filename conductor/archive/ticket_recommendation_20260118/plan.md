# 계획: 파티 입장 조건에 맞는 최적 티켓 자동 추천 및 구매 제한

## Phase 1: 티켓 추천 로직 구현 및 테스트 (`app_user`)
- [ ] Task: 최적 티켓 선별 함수 구현
    - [ ] `EventAdmissionController` 또는 관련 유틸리티에 유저 프로필과 티켓 리스트를 받아 가장 저렴한 티켓을 반환하는 로직 작성.
- [ ] Task: 추천 로직 단위 테스트 작성
    - [ ] 다양한 조건(얼리버드 존재, 다수 그룹 해당 등)에서 가장 저렴한 티켓이 올바르게 뽑히는지 검증.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 추천 로직 동작 확인' (Protocol in workflow.md)

## Phase 2: UI 연동 및 수량 제한 구현 (`app_user`)
- [ ] Task: 티켓 선택 UI 단순화
    - [ ] 상세 페이지 및 신청 마법사에서 여러 티켓을 보여주는 리스트를 제거하고, 자동 선정된 티켓 하나만 카드 형태로 표시하도록 수정.
- [ ] Task: 수량 제한 및 피드백 연동
    - [ ] 수량 증가 시도 시 `context.showMinglitInfo('친구와 함께 참가하기 기능은 준비 중입니다.')` 호출 및 로직 차단.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: UI 및 수량 제한 확인' (Protocol in workflow.md)

## Phase 3: 최종 검증 및 아카이브
- [ ] Task: 통합 테스트 시나리오 수행
    - [ ] `integration_scenario_tester`를 통해 실제 신청 플로우에서 티켓 자동 선택이 잘 되는지 확인.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 전체 플로우 최종 확인' (Protocol in workflow.md)
