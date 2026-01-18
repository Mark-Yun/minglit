# Implementation Plan: MinglitAsyncValueWidget

- [ ] **Step 1: 위젯 구현 (`minglit_kit`)**
  - `lib/src/ui/widgets/common/minglit_async_value_widget.dart` 생성.
  - `MinglitAsyncValueWidget` 클래스 구현 (기본 로딩/에러 UI 포함).
  - `lib/minglit_ui.dart`에 익스포트 추가.

- [ ] **Step 2: `app_user` 적용 (Refactor)**
  - `HomePage`, `EventDetailScreen`, `PartyCurationScreen` 등에서 기존 `.when()` 호출부를 `MinglitAsyncValueWidget`으로 교체.

- [ ] **Step 3: `app_partner` 적용 (Refactor)**
  - `PartyListPage`, `EventDetailPage`, `VerificationManageScreen` 등 주요 화면의 비동기 처리 로직 교체.

- [ ] **Step 4: 검증 및 정리**
  - 앱 실행 후 로딩/에러 상태가 의도한 대로 표시되는지 확인.
  - 불필요해진 임포트 및 보일러플레이트 코드 정리.
