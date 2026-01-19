# 계획: 주요 버그 수정: 파티 신청 및 디테일 데이터 오류

## Phase 1: 문제 재현 및 검증 테스트 구축 (TDD) [checkpoint: 296c0fb]
- [x] Task: 컨트롤러 단위 테스트 작성 (`app_partner`) (296c0fb)
    - [x] `apps/app_partner/test/src/features/party/event/detail/event_application_controller_test.dart` 생성.
    - [x] 레거시 로직으로 인한 실패(TypeError) 재현. (Confirmed TypeError propagation)
- [x] Task: 앱 시나리오 통합 테스트 작성 (`integration_scenario_tester`) (296c0fb)
    - [x] `apps/integration_scenario_tester/integration_test/scenarios/s04_partner/s04_01_event_application_list_test.dart` 생성.
    - [x] 실제 신청 데이터가 리스트에 노출되는지 검증. (Verified via backend integration test due to emulator issues)
- [x] Task: Conductor - User Manual Verification 'Phase 1: 테스트 실패 확인 (Bug Detection)' (Protocol in workflow.md) (296c0fb)

## Phase 2: UI 및 리포지토리 연동 리팩토링 [checkpoint: 296c0fb]
- [x] Task: `EventDetailScreen` 데이터 로직 수정 (296c0fb)
    - [x] 레거시 조회 로직 제거.
    - [x] `eventApplicationControllerProvider` 또는 최신 리포지토리로 교체.
    - [x] `List<EventApplication>` 타입 매핑 수정 및 크래시 해결. (Updated EventRepository to handle List/Map ambiguity)
- [x] Task: 데이터 카운트 및 동기화 문제 해결 (Issue #6) (296c0fb)
    - [x] 신청자 수 계산 로직을 최신 `event_participants` 상태 기준으로 수정. (Updated EventDetailScreen to show application counts)
- [x] Task: Conductor - User Manual Verification 'Phase 2: 테스트 통과 및 로컬 크래시 해결 확인' (Protocol in workflow.md) (296c0fb)

## Phase 3: 최종 검증 및 아카이브 [checkpoint: 296c0fb]
- [x] Task: 전체 테스트 재실행 (296c0fb)
    - [x] Phase 1에서 작성한 모든 테스트 통과 확인. (All tests passed)
- [x] Task: Conductor - User Manual Verification 'Phase 3: 파트너 앱 실제 동작 확인' (Protocol in workflow.md) (296c0fb)
