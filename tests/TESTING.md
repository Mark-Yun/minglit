# Minglit Testing Strategy

Minglit 프로젝트의 테스트는 **"신뢰할 수 있는 만남"**이라는 브랜드 가치를 기술적으로 보장하기 위해 인프라, 비즈니스 로직, UI 세 계층으로 나누어 관리합니다.

---

## 1. 테스트 계층 구조 (Testing Pyramid)

### 🧱 인프라 테스트 (Infrastructure Verification)
- **위치:** `supabase/` (pgTAP, Edge Function Deno 테스트)
- **환경:** `supabase test db` (pgTAP), `deno test` (Edge Functions)
- **대상:** Supabase 데이터베이스 (SQL 스키마, RLS 보안 정책, Database Triggers, Functions).
- **목표:** DB 자체가 비즈니스 규칙과 보안 정책을 완벽하게 수행하는지 검증합니다.

### 🔄 E2E 시뮬레이션 (Server-side E2E)
- **위치:** `supabase/functions/e2e-test-runner/`
- **환경:** Supabase Edge Function (pg_cron 매시간 자동 실행)
- **대상:** 전체 비즈니스 파이프라인 (파티 생성 → 신청 → 인증 심사 → 결제 → 체크인 → 매칭 → 정산).
- **목표:** 프로덕션과 동일한 환경에서 6-phase 시뮬레이션을 통해 end-to-end 비즈니스 로직 검증.
- **특징:** 실패 시 GitHub Issue 자동 생성, 로그를 Storage에 업로드.

### 🧠 CUJ E2E 테스트 (Client-side E2E)
- **위치:** `tests/e2e_automation_tester/`
- **환경:** Flutter integration_test (GitHub Actions daily cron, KST 07:00)
- **대상:** `minglit_kit` (Repositories, Providers) + dev Supabase 서버 연동.
- **목표:** 6개 Critical User Journey가 실제 서버 환경에서 정상 동작하는지 매일 검증합니다.
- **실행:** `.github/workflows/daily-e2e.yml`

### 🎨 UI 통합 및 위젯 테스트 (UI & Interaction Verification)
- **위치:** `apps/app_user/test/integration/`, `apps/app_partner/test/`
- **환경:** Flutter Engine (headless)
- **대상:** 화면(Screen), 위젯(Widget), 사용자 인터랙션 흐름.
- **목표:** 사용자가 버튼을 눌렀을 때 화면이 기대한 대로 바뀌는지 검증합니다.
- **특징:** Mock Repository를 사용하여 네트워크 변수를 배제하고 UI 동작 자체에 집중합니다.

---

## 2. 테스트 데이터 관리

- **로컬/dev 시딩:** `supabase/functions/dev-seed/` Edge Function (`curl -X POST .../functions/v1/dev-seed`)
- **E2E 시뮬레이션:** `e2e-test-runner`가 자체적으로 테스트 데이터를 생성 및 정리합니다.

---

## 3. 코드 커버리지 목표
- **`minglit_kit` (핵심 로직):** 커버리지 **80%** 이상 권장.
- **Critical Flow (결제, 매칭):** 테스트 시나리오 필수 포함.

---

## 4. CI/CD 통합
- PR 시 `ci.yml`에서 pgTAP + Edge Function 테스트 + Flutter analyze/test 자동 실행.
- 매일 KST 07:00 `daily-e2e.yml`로 CUJ E2E 테스트 실행.
- 매시간 `e2e-test-runner` pg_cron으로 서버사이드 E2E 시뮬레이션 실행.
