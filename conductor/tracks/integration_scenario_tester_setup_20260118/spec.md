# 클라이언트 시나리오 통합 테스트 구축 명세서 (Spec)

## 1. 개요
`minglit_kit`의 비즈니스 로직과 Supabase 간의 연동을 실제 Flutter 환경에서 검증하기 위한 전용 테스트 앱 `integration_scenario_tester`를 구축합니다. 이 앱은 시나리오 기반의 통합 테스트를 수행하며, 테스트 데이터 공급을 위해 `test_data_seeder`를 내장합니다.

## 2. 테스트 전략 및 역할 분담 (`tests/TESTING.md`)
프로젝트 전반의 테스트 계층을 다음과 같이 정의하고 문서화합니다.
- **인프라 테스트 (`tests/backend_integration`)**: Supabase SQL, RLS, Trigger 검증 (Dart CLI).
- **시나리오 통합 테스트 (`apps/integration_scenario_tester`)**: `minglit_kit` 로직 + 실제 DB 연동 검증 (Flutter).
- **UI 통합 테스트 (`apps/app_user/integration_test` 등)**: 화면 전환 및 사용자 인터랙션 검증 (Flutter, Mock DB 권장).

## 3. 기능 요구사항
- **전용 테스트 앱 구축**: `apps/integration_scenario_tester` (최소 위젯 구조).
- **시더 통합 (Data Preparation)**: 테스트 코드의 `setUpAll` 또는 `setUp` 단계에서 `test_data_seeder`를 호출하여 필요한 환경(유저, 이벤트 등)을 동적으로 생성.
- **자동화 실행 (CLI Focused)**: `flutter test integration_test` 명령어를 통해 실행하며, CI/CD 연동이 용이한 구조.
- **첫 번째 검증 시나리오**:
    - **Scenario A (Matching)**: 특정 유저들이 서로를 지목했을 때 실시간 매칭 결과가 생성되고 연락처가 공개되는지 검증.
    - **Scenario B (Auth/Signup)**: 본인인증 로직부터 가입 완료, 프로필 생성까지의 전체 흐름 검증.

## 4. 기술 스택
- **Framework**: Flutter
- **Testing**: `integration_test` (Flutter SDK), `flutter_test`
- **Logic**: `minglit_kit` (Source of Truth)
- **Data**: `tests/test_data_seeder`
