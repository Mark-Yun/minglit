# Implementation Plan: Enhance Lint Rules

- [ ] **Step 1: 하드코딩 색상 금지 규칙 구현 (`no_hardcoded_colors`)**
  - `lib/src/no_hardcoded_colors_rule.dart` 생성.
  - `Color` 생성자와 `Colors` 스태틱 멤버 접근을 감지하는 로직 구현.
  - `minglit_lints.dart`에 규칙 등록.

- [ ] **Step 2: 하드코딩 텍스트 스타일 금지 규칙 구현 (`no_hardcoded_text_style`)**
  - `lib/src/no_hardcoded_text_style_rule.dart` 생성.
  - `TextStyle` 생성자 호출을 감지하는 로직 구현.
  - `minglit_lints.dart`에 규칙 등록.

- [ ] **Step 3: 버전 범프 및 검증**
  - `pubspec.yaml` 버전 업데이트 (0.0.2).
  - `apps/app_user`에서 `dart run custom_lint`로 검증 (가능하다면).
