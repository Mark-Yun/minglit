# Implementation Plan: Apply MinglitAsyncValueWidget

- [~] **Step 0: `minglit_lints` 규칙 추가**
  - `lib/src/use_minglit_async_value_widget_rule.dart` 구현.
  - `AsyncValue.when`, `maybeWhen` 호출 감지.
  - `minglit_lints.dart`에 등록 및 앱 `analysis_options.yaml` 활성화.

- [x] **Step 1: `app_user` 전체 적용**
  - `grep`으로 `when(` 패턴 검색.
  - 각 파일별로 `MinglitAsyncValueWidget`으로 리팩토링.
  - 주요 대상: `PartyCurationScreen`, `EventDetailScreen` 등 (이미 된 곳은 패스).

- [x] **Step 2: `app_partner` 전체 적용**
  - 린트 규칙이 활성화되면 자동으로 감지되는 위반 사항 수정.
  - `grep` 결과에 따른 추가 확인.

- [x] **Step 3: `minglit_kit` 전체 적용**
  - 공용 위젯 내 비동기 처리 로직 리팩토링.

- [x] **Step 4: 검증**
  - `flutter analyze` 및 `dart run custom_lint`로 에러 및 린트 위반 여부 확인.
  - 앱 실행 후 주요 화면 로딩/에러 상태 확인.