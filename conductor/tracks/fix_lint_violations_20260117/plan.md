# Implementation Plan: Fix Lint Violations

- [ ] **Phase 1: `app_user` UI 컴포넌트 수정**
  - [ ] `apps/app_user/lib/src/features/home/home_page.dart` 수정
  - [ ] `apps/app_user/lib/src/features/event/admission/event_application_wizard_screen.dart` 수정
  - [ ] 기타 `app_user` 내 UI 파일 순차 수정

- [ ] **Phase 2: `app_partner` UI 컴포넌트 수정**
  - [ ] `apps/app_partner/lib/src/features/` 내 UI 파일 수정

- [ ] **Phase 3: `minglit_kit` 공용 위젯 수정 및 정리**
  - [ ] `shared/packages/minglit_kit/lib/src/ui/` 내 위젯 수정

- [ ] **Phase 4: 전체 검증**
  - [ ] `flutter analyze` 및 `custom_lint` 실행 (No Issues Found 확인)
