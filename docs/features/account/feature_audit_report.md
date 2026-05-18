# Feature Audit Report — `account` · `2026-05-18`

> 인스펙션 리포트. `FRESH_DOC` cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다. 본 문서는 **감사 추적(audit trail)** 이며, 직접 편집하지 않는다.
>
> 새 feature 의 PRD/spec 작성: [`_template/prd.md`](../_template/prd.md) · [`_template/spec.md`](../_template/spec.md). 컨벤션: [`BLUEDOC.md`](../BLUEDOC.md).

## Summary

`account` 카테고리 (feature 6개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | `0` | — |
| P1 — Defect / Gap | `0` | — |
| P2 — Improvement | `1` | `#2555` |
| P3 — Low | `1` | `#2556` |

---

## Action Items by Priority

> 본 audit 의 모든 발견 사항을 처리 우선순위로 정렬. 각 항목은 GitHub Issue 1건과 1:1 매핑.

### P0 — Critical (즉시 처리)

_해당 없음_

### P1 — Defect / Gap (이번 스프린트)

_해당 없음_

### P2 — Improvement (다음 스프린트)

- [ ] **#2555** `[3-1]` `account/account-deletion` — app_user account-deletion CUJ integration test 완전 누락 (spec P0 CUJ 1-1~3-4 미검증). widget test 4개는 있으나 coordinator 흐름 + 상태 전이 미검증. **Action**: `apps/app_user/integration_test/cuj/account/account_deletion_test.dart` 신규 작성 (CUJ 1-1, 1-3, 1-4, 3-1 우선). **Evidence**: `apps/app_user/integration_test/cuj/account/` — `signup_consent_test.dart` 만 존재.

### P3 — Low (여유 시)

- [ ] **#2556** `[1-1]` `account/account-management`, `account/login-dark-theme`, `account/privacy-protection` — 3개 feature prd.md + spec.md 부재 (wireframe.html 또는 구형 ui-ux-design.md 만 보유). **Action**: `docs/features/_template/` 기반 prd.md + spec.md 신규 작성. **Evidence**: `docs/features/account/{account-management,login-dark-theme,privacy-protection}/` — prd.md/spec.md 없음.

---

## 1. Spec 점검

**Method**: `docs/features/account/<feature>/` 내 `prd.md` + `spec.md` 를 `BLUEDOC.md` 5섹션 컨벤션 + `_template/` + canonical example (`account/signup-consent/`) 와 대조.

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | `account-management`, `login-dark-theme`, `privacy-protection` (3개) |
| Summary / Motivation 누락 | `account-management`, `login-dark-theme`, `privacy-protection` (prd.md 없으므로) |
| Goals 의 P0/P1 / Non-Goals 모호 | 해당 없음 (기존 prd.md 3개는 P0/P1/Non-Goals 명확) |
| User Journey ↔ CUJ ID prefix 매핑 누락 | 해당 없음 |

### 1-2. spec.md 5섹션 완성도

| 점검 | 결과 |
|------|------|
| spec.md 부재 features | `account-management`, `login-dark-theme`, `privacy-protection` (3개) |
| 5섹션 구조 미적용 | `privacy-protection` — `ui-ux-design.md` (v1.0 구형 포맷, #556) |
| CUJs 테이블 행 부족 | 해당 없음 (기존 spec.md 3개 — CUJ 테이블 충분) |
| FR ↔ CUJ 매핑 누락 | 해당 없음 |
| NFR 측정 불가능 | 해당 없음 (기존 spec.md NFR 모두 p50/p95/환경 명시) |
| Edge Cases 비어있음 | 해당 없음 |
| Open Questions 1주+ 방치 | `account-deletion/spec.md` — 6개 Open Q 중 "DI 변경된 재가입", "유예 기간 중 매칭" 등 결정 미완료 (작성일 불명, 보강 권장) |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario 와 spec.md CUJ ID prefix 불일치 | 해당 없음 (3개 spec.md 모두 정합) |
| spec.md 참조 MDS state PNG 부재 | `partner-terms-privacy/spec.md` — "디자인 TODO (landing 페이지는 MDS spec 미생성)" 명시 (landing 특성상 MDS spec 없음 — 허용됨) |
| 개발 detail 이 spec.md 에 포함됨 | 해당 없음 (provider/SQL/메서드 시그니처 미포함) |

**MDS spec 커버리지**:

| 화면 | MDS spec 존재 |
|------|--------------|
| `deletion_reason_page` | ✓ |
| `deletion_info_page` | ✓ |
| `deletion_verify_page` | ✓ |
| `deletion_complete_page` | ✓ |
| `account_management_page` | ✓ |
| `privacy_page` | ✓ |
| `signup_consent_page` | ✓ |
| `login_page` / `partner_login_page` | ✓ |

**Findings**:
- `#2556` — account-management, login-dark-theme, privacy-protection prd.md + spec.md 부재. Evidence: `docs/features/account/`. Severity: `P3`.

---

## 2. UI 완성도

**Method**: MDS spec (디자인 의도) ↔ 앱 render (실 구현) 비교.

### 2-1. MDS spec 완성도

| 점검 | 결과 |
|------|------|
| CUJ Details 에 언급된 상태가 MDS state PNG 로 존재 | 검사 불가 (emulator render 환경 미구성) |
| MDS state PNG 수가 spec CUJ 수에 비해 부족 | 검사 불가 |

### 2-2. 앱 render coverage

| 점검 | 결과 |
|------|------|
| mds-emulator-render 미등록 screen | `mds_render_coverage.dart` 미실행 (환경 미구성) |
| catalog 됐지만 state 불충분 | 검사 불가 |
| catalog 됐지만 MDS spec 없음 | 검사 불가 |

### 2-3. 앱 render ↔ MDS spec drift

시각 비교 미수행 (emulator render 환경 미구성).

**Findings**: 해당 없음 (검사 불가 항목은 다음 사이클 환경 구성 후 재검사 권장)

---

## 3. 테스트 현황

### 3-1. app_user

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| Unit | `apps/app_user/test/src/` | account 카테고리 비즈니스 로직 | `consent_coordinator_test.dart` ✓ |
| Widget | `apps/app_user/test/src/features/` | 화면별 widget test | deletion 4개 ✓ / consent 2개 ✓ / privacy 1개 ✓ |
| CUJ integration | `apps/app_user/integration_test/cuj/account/` | spec.md CUJ ↔ cujGroup 매핑 | `signup_consent_test.dart` ✓ / **`account_deletion_test.dart` 없음** ❌ |

### 3-2. app_partner

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| Unit | `apps/app_partner/test/src/` | account 카테고리 | 검사 미수행 |
| Widget | `apps/app_partner/test/` | 화면별 widget test | 검사 미수행 |
| CUJ integration | `apps/app_partner/integration_test/cuj/account/` | spec.md CUJ ↔ cujGroup | `partner_account_deletion_test.dart` (CUJ 1-1 only) ✓ / **CUJ 2-1, 2-2 없음** |

### 3-3. Backend

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| EF Deno Unit | `supabase/functions/` | account 관련 EF | 검사 미수행 |
| Supabase pgTAP | `supabase/tests/database/` | RPC / trigger / RLS | `56_user_consents_test.sql` ✓ / `57_account_deletion_foundation_test.sql` ✓ / `89_account_deletion_immediate_purge_test.sql` ✓ / `100_marketing_consent_renewal_test.sql` ✓ |

### 3-4. CI 실패 패턴

- 최근 7일 account 카테고리 관련 CI 실패: 없음 (`gh pr list --search updated:>7d` — account PR 0건)
- 플레이키 사례: 해당 없음

**Findings**:
- `#2555` — app_user account-deletion CUJ integration test 완전 누락. Evidence: `apps/app_user/integration_test/cuj/account/` — signup_consent만 존재. Severity: `P2`.

---

## Findings (issue filing)

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|----------|----------|----------|--------|
| `#2555` | `3-1` | app_user account-deletion CUJ integration test 없음 (P0 CUJ 1-1~3-4 미검증) | `apps/app_user/integration_test/cuj/account/` | `P2` | `M` |
| `#2556` | `1-1` | account-management, login-dark-theme, privacy-protection prd.md + spec.md 부재 | `docs/features/account/{account-management,login-dark-theme,privacy-protection}/` | `P3` | `M` |

---

## Inputs Consulted

| 입력 | 경로 / 도구 |
|------|-----------|
| PRD / spec | `docs/features/account/{account-deletion,partner-terms-privacy,signup-consent}/{prd,spec}.md` |
| Templates | `docs/features/_template/{prd,spec}.md` |
| BLUEDOC | `docs/features/account/BLUEDOC.md` |
| MDS spec 목록 | `apps/mds/docs/public/specs/` — deletion*/account*/privacy*/signup* |
| app_user CUJ tests | `apps/app_user/integration_test/cuj/account/` |
| app_partner CUJ tests | `apps/app_partner/integration_test/cuj/account/` |
| app_user widget tests | `apps/app_user/test/src/features/account_deletion/`, `consent/`, `settings/` |
| Supabase pgTAP | `supabase/tests/database/56_*, 57_*, 89_*, 100_*` |
| Recent activity | `gh issue list / pr list` (최근 7일, account 키워드) |

---

## Run Metadata

- Agent: `swe-sonnet-1`
- Duration: `~30min`
- Cycle: `14d` (next: `2026-06-01`)
- Template version: `c6bd89a1e`
