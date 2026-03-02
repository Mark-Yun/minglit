# 계획: 유저앱 알림 설정 화면 구현

## Phase 1: 데이터 레이어 및 리포지토리 보강 (minglit_kit)
- [ ] Task: `NotificationSettings` 모델 정의 및 DB 연동
    - [ ] `shared/packages/minglit_kit` 내에 알림 설정 데이터 모델 생성 (`party_alerts`, `marketing_alerts`).
    - [ ] `NotificationRepository`에 설정 조회 및 업데이트 메서드 추가.
- [ ] Task: 리포지토리 단위 테스트 작성
    - [ ] Mock Supabase를 활용하여 설정 조회/수정 로직 검증.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 데이터 레이어 검증' (Protocol in workflow.md)

## Phase 2: 상태 관리 로직 구현 (app_user)
- [ ] Task: `NotificationSettingsController` (Riverpod) 구현
    - [ ] 서버로부터 설정을 로드하고, 토글 시 즉시 반영하는 `AsyncNotifier` 기반 컨트롤러 작성.
    - [ ] 로딩 및 에러 핸들링 로직 포함.
- [ ] Task: 컨트롤러 테스트 코드 작성
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 로직 및 상태 변화 확인' (Protocol in workflow.md)

## Phase 3: UI 구현 및 네비게이션 연동 (app_user)
- [ ] Task: 알림 설정 화면 UI 구현
    - [ ] `NotificationSettingsScreen` 작성 (디자인 토큰 준수).
    - [ ] 각 설정 항목에 대해 `SwitchListTile` 적용.
- [ ] Task: 마이페이지 진입점 및 라우팅 추가
    - [ ] `GoRouter`를 이용한 화면 이동 정의.
    - [ ] 마이페이지 설정 리스트에 '알림 설정' 항목 추가.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 화면 및 인터랙션 테스트' (Protocol in workflow.md)

## Phase 4: 최종 품질 검증 및 정제
- [ ] Task: 코드 품질 강화 루프 실행
    - [ ] `dart fix --apply`, `dart format .`, `flutter analyze` (Zero Warning 달성).
- [ ] Task: 최종 빌드 및 수동 검증
- [ ] Task: Conductor - User Manual Verification 'Phase 4: 전체 시스템 통합 검증' (Protocol in workflow.md)
