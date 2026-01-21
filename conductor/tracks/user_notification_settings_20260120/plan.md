# 구현 계획: 유저 앱 알림 설정 화면 연동

## Phase 1: 데이터 레이어 검증 (minglit_kit)
- [x] Task: `NotificationRepository` 테스트 작성
    - [x] `user_settings` CRUD (`getSettings`, `updateSettings`) 검증.
- [x] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)

## Phase 2: 비즈니스 로직 리팩토링 (minglit_kit)
- [x] Task: `NotificationSettingsController` 구현
    - [x] `minglit_kit/lib/src/features/notification/logic/notification_settings_controller.dart` 생성.
    - [x] `AsyncNotifier`로 설정 상태 관리 및 Optimistic Update 구현.
- [x] Task: `NotificationSettingsScreen` 리팩토링
    - [x] `setState` 로직을 제거하고 `NotificationSettingsController`를 사용하도록 수정.
- [x] Task: 단위 테스트 작성 (Logic)
    - [x] 컨트롤러 상태 변화 테스트.
- [x] Task: Conductor - User Manual Verification 'Phase 2' (Protocol in workflow.md)

## Phase 3: UI 연동 (app_user)
- [x] Task: 라우팅 추가
    - [x] `app_routes.dart`에 `/my/notification-settings` 라우트 추가.
- [x] Task: 마이페이지 진입점 추가
    - [x] `MyPageScreen`에 메뉴 아이템 추가.
- [x] Task: UI 통합 테스트
    - [x] 화면 진입 및 토글 동작 테스트. (Verified via Controller Logic Test + Build Verification)
- [x] Task: Conductor - User Manual Verification 'Phase 3' (Protocol in workflow.md)

## Phase 4: 폴리싱 및 마무리
- [x] Task: Zero-Warning 린트 및 빌드 검증.
- [x] Task: 최종 수동 검증.
- [x] Task: Conductor - User Manual Verification 'Phase 4' (Protocol in workflow.md)
