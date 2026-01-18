# Minglit Testing Strategy

Minglit 프로젝트의 테스트는 **"신뢰할 수 있는 만남"**이라는 브랜드 가치를 기술적으로 보장하기 위해 인프라, 비즈니스 로직, UI 세 계층으로 나누어 관리합니다.

---

## 1. 테스트 계층 구조 (Testing Pyramid)

### 🧱 인프라 테스트 (Infrastructure Verification)
- **위치:** `tests/backend_integration/`
- **환경:** Dart CLI (터미널)
- **대상:** Supabase 데이터베이스 (SQL 스키마, RLS 보안 정책, Database Triggers, Functions).
- **목표:** DB 자체가 비즈니스 규칙과 보안 정책을 완벽하게 수행하는지 검증합니다.
- **실행:** `cd tests/backend_integration && dart test`

### 🧠 시나리오 통합 테스트 (Logic & Scenario Verification)
- **위치:** `apps/integration_scenario_tester/`
- **환경:** Flutter Engine (에뮬레이터/기기)
- **대상:** `minglit_kit` (Repositories, Providers) + 실제 Supabase DB 연동.
- **목표:** 앱의 비즈니스 로직이 실제 서버 환경에서 시나리오대로(예: 회원가입 -> 매칭 -> 연락처 확인) 동작하는지 검증합니다.
- **특징:** UI 없이 순수 로직 흐름만 테스트하며, `test_data_seeder`를 내장하여 테스트 환경을 동적으로 준비합니다.
- **실행:** `cd apps/integration_scenario_tester && flutter test integration_test`

### 🎨 UI 통합 및 위젯 테스트 (UI & Interaction Verification)
- **위치:** `apps/app_user/integration_test/`, `apps/app_partner/integration_test/`
- **환경:** Flutter Engine
- **대상:** 화면(Screen), 위젯(Widget), 사용자 인터랙션 흐름.
- **목표:** 사용자가 버튼을 눌렀을 때 화면이 기대한 대로 바뀌는지 검증합니다.
- **특징:** 가능한 경우 Fake/Mock Repository를 사용하여 네트워크 변수를 배제하고 UI 동작 자체에 집중합니다.
- **실행:** `flutter test integration_test` (각 앱 폴더 내)

---

## 2. 테스트 데이터 관리 (`test_data_seeder`)

모든 통합 테스트는 **`tests/test_data_seeder`** 패키지에 의존합니다.
- 테스트의 `setUpAll` 또는 `setUp` 단계에서 시더를 호출하여 필요한 유저, 파티, 티켓 등을 생성합니다.
- 테스트 완료 후 또는 시작 전 데이터를 초기화하여 **테스트 격리(Isolation)**를 유지합니다.

---

## 3. 코드 커버리지 목표
- **`minglit_kit` (핵심 로직):** 커버리지 **80%** 이상 권장.
- **Critical Flow (결제, 매칭):** 테스트 시나리오 필수 포함.

---

## 4. CI/CD 통합
- 모든 `git push` 시 `backend_integration` 테스트가 자동으로 실행됩니다.
- 주요 릴리스 전 `integration_scenario_tester`를 통해 전체 시나리오를 검증합니다.
