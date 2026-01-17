# Implementation Plan: Minglit Custom Lints

- [ ] **Step 1: 린트 패키지 스캐폴딩 (Scaffold Package)**
  - `shared/packages/minglit_lints` 디렉토리에 Dart 패키지 생성.
  - `pubspec.yaml`에 `analyzer`, `custom_lint_builder` 의존성 추가.
  - `tools/analyzer_plugin/bin/plugin.dart` 엔트리포인트 파일 생성.
  - `lib/minglit_lints.dart` 마커 파일 생성.

- [ ] **Step 2: 하드코딩 패딩 금지 규칙 구현 (No Hardcoded Padding Rule)**
  - `lib/src/no_hardcoded_padding_rule.dart` 생성.
  - `DartLintRule`을 상속받아 `NoHardcodedPaddingRule` 클래스 구현.
  - `Padding` 위젯과 `EdgeInsets` 생성자에 숫자 리터럴이 사용되는지 검사하는 로직 작성 (AST Visitor).
  - Plugin 엔트리포인트에 규칙 등록.

- [ ] **Step 3: 공용 인디케이터 강제 규칙 구현 (Common Progress Indicator Rule)**
  - `lib/src/use_minglit_progress_indicator_rule.dart` 생성.
  - `DartLintRule`을 상속받아 `UseMinglitProgressIndicatorRule` 클래스 구현.
  - `CircularProgressIndicator`와 `LinearProgressIndicator` 사용을 감지하는 로직 작성.
  - Plugin 엔트리포인트에 규칙 등록.

- [ ] **Step 4: 앱 통합 및 적용 (Integration)**
  - `apps/app_user/pubspec.yaml`에 `minglit_lints`를 `dev_dependency`로 추가.
  - `apps/app_user/analysis_options.yaml`에 `custom_lint` 플러그인 활성화.
  - `apps/app_partner`에도 동일하게 적용.

- [ ] **Step 5: 검증 (Verification)**
  - `apps/app_user` 내에 테스트용 위젯 파일을 생성하여 규칙 위반 코드 작성.
  - `dart run custom_lint` 실행하여 경고 메시지가 정상적으로 출력되는지 확인.
  - 테스트 파일 삭제.
