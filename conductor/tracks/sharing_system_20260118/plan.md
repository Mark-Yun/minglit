# Plan: Sharing System

## Phase 1: Setup & Dependencies
- [ ] Task: `minglit_kit` 패키지에 `share_plus` 의존성 추가
- [ ] Task: `apps/app_user`에서 `flutter pub get` 실행 및 의존성 동기화
- [ ] Task: Conductor - User Manual Verification 'Setup & Dependencies' (Protocol in workflow.md)

## Phase 2: Core Implementation (TDD)
- [ ] Task: `minglit_kit`에 `SharingService` 구현
    - [ ] Sub-task: `shareUrl` 및 `shareText` 메서드를 포함한 서비스 클래스 정의
    - [ ] Sub-task: 이벤트 정보를 포맷팅하여 공유하는 `shareEvent(Event event)` 메서드 구현
    - [ ] Sub-task: `SharingService` 단위 테스트 작성 (포맷팅 로직 검증 등)
- [ ] Task: Conductor - User Manual Verification 'Core Implementation' (Protocol in workflow.md)

## Phase 3: UI Integration
- [ ] Task: `app_user`의 `EventDetailScreen`에 공유 기능 연동
    - [ ] Sub-task: AppBar 또는 적절한 위치에 '공유' 아이콘 버튼 추가
    - [ ] Sub-task: 버튼 클릭 시 `SharingService.shareEvent` 호출 연결
- [ ] Task: Conductor - User Manual Verification 'UI Integration' (Protocol in workflow.md)

## Phase 4: Verification & Polish
- [ ] Task: 전체 정적 분석(`analyze_files`) 실행 및 린트 에러 해결
- [ ] Task: iOS/Android 시뮬레이터에서 공유 시트 동작 수동 검증
- [ ] Task: Conductor - User Manual Verification 'Verification & Polish' (Protocol in workflow.md)
