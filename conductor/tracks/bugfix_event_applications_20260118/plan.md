# 계획: 주요 버그 수정: 파티 신청 및 디테일 데이터 오류

## Phase 1: 문제 재현 및 검증 테스트 구축 (TDD)
- [ ] Task: 컨트롤러 단위 테스트 작성 (`app_partner`)
    - [ ] `apps/app_partner/test/src/features/party/event/detail/event_application_controller_test.dart` 생성.
    - [ ] 레거시 로직으로 인한 실패(TypeError) 재현.
- [ ] Task: 앱 시나리오 통합 테스트 작성 (`integration_scenario_tester`)
    - [ ] `apps/integration_scenario_tester/integration_test/scenarios/s04_partner/s04_01_event_application_list_test.dart` 생성.
    - [ ] 실제 신청 데이터가 리스트에 노출되는지 검증.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 테스트 실패 확인 (Bug Detection)' (Protocol in workflow.md)

## Phase 2: UI 및 리포지토리 연동 리팩토링
- [ ] Task: `EventDetailScreen` 데이터 로직 수정
    - [ ] 레거시 조회 로직 제거.
    - [ ] `eventApplicationControllerProvider` 또는 최신 리포지토리로 교체.
    - [ ] `List<EventApplication>` 타입 매핑 수정 및 크래시 해결.
- [ ] Task: 데이터 카운트 및 동기화 문제 해결 (Issue #6)
    - [ ] 신청자 수 계산 로직을 최신 `event_participants` 상태 기준으로 수정.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 테스트 통과 및 로컬 크래시 해결 확인' (Protocol in workflow.md)

## Phase 3: 최종 검증 및 아카이브
- [ ] Task: 전체 테스트 재실행
    - [ ] Phase 1에서 작성한 모든 테스트 통과 확인.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 파트너 앱 실제 동작 확인' (Protocol in workflow.md)
