# Minglit Testing Strategy

Minglit 프로젝트의 테스트는 4개 계층으로 관리합니다.

---

## 1. 테스트 계층 구조

### 🧱 인프라 단위 테스트 (Infrastructure Unit)
- **위치:** `supabase/` (pgTAP, Edge Function Deno 테스트)
- **환경:** `supabase test db` (pgTAP), `deno test` (Edge Functions)
- **대상:** SQL 스키마, RLS 정책, Database Triggers, Functions, Edge Functions.
- **목표:** DB와 서버 함수가 개별적으로 올바르게 동작하는지 검증.

### 🔄 백엔드 시뮬레이션 (Backend Simulator)
- **위치:** `supabase/functions/backend-simulator/`
- **환경:** Supabase Edge Function (pg_cron 매시간 자동 실행)
- **대상:** 전체 비즈니스 파이프라인 (파티 생성 → 신청 → 인증 심사 → 결제 → 체크인 → 매칭 → 정산).
- **목표:** 6-phase 시뮬레이션으로 서버사이드 비즈니스 로직이 파이프라인 전체에서 정합성을 유지하는지 검증.
- **특징:** 실패 시 GitHub Issue 자동 생성, 로그를 Storage에 업로드.

### 🧠 클라이언트 CUJ 통합 테스트 (Client CUJ Integration)
- **위치:** `tests/client_cuj_integration/`
- **환경:** Flutter integration_test (GitHub Actions daily cron, KST 07:00)
- **대상:** `minglit_kit` (Repositories, Providers) + dev Supabase 서버 연동.
- **목표:** 6개 Critical User Journey가 클라이언트 로직 레벨에서 실제 서버와 정상 연동되는지 매일 검증. UI 없이 Repository/Provider 레벨만 테스트.
- **실행:** `.github/workflows/daily-e2e.yml`

### 🎨 위젯 테스트 (Widget / UI Test)
- **위치:** `apps/app_user/test/integration/`, `apps/app_partner/test/`
- **환경:** Flutter Engine (headless, Mock 기반)
- **대상:** 화면(Screen), 위젯(Widget), 사용자 인터랙션 흐름.
- **목표:** Mock 데이터 기반으로 UI 렌더링과 네비게이션이 기대한 대로 동작하는지 검증. 네트워크 의존성 없음.

---

## 2. 테스트 데이터 관리

- **로컬/dev 시딩:** `supabase/functions/dev-seed/` Edge Function (`curl -X POST .../functions/v1/dev-seed`)
- **백엔드 시뮬레이션:** `backend-simulator`가 자체적으로 테스트 데이터를 생성 및 정리.

---

## 3. 코드 커버리지 목표
- **`minglit_kit` (핵심 로직):** 커버리지 **80%** 이상 권장.
- **Critical Flow (결제, 매칭):** 테스트 시나리오 필수 포함.

---

## 4. CI/CD 통합
- PR 시 `ci.yml`에서 pgTAP + Edge Function 테스트 + Flutter analyze/test 자동 실행.
- 매일 KST 07:00 `daily-e2e.yml`로 클라이언트 CUJ 통합 테스트 실행.
- 매시간 `backend-simulator` pg_cron으로 서버사이드 시뮬레이션 실행.
