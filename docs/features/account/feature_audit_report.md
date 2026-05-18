# Feature Audit Report — `account` · `2026-05-18`

> 인스펙션 리포트. FRESH_DOC cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다.

## Summary

`account` 카테고리 (feature 6개, spec 보유 3개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | 0 | — |
| P1 — Defect / Gap | 0 | — |
| P2 — Improvement | 2 | #2555, #2556 |
| P3 — Low | 0 | — |

## Action Items by Priority

### P2 — Improvement (다음 스프린트)

- [ ] **#2555** `[3-1]` `account/account-deletion` — app_user CUJ integration test 누락 (26 CUJs 미검증). **Action**: `apps/app_user/integration_test/cuj/account/account_deletion_test.dart` 신규 작성. **Evidence**: 디렉토리 내 `signup_consent_test.dart`만 존재. *(PR #2567 in review)*
- [ ] **#2556** `[1-1]` `account/account-management` + `account/login-dark-theme` + `account/privacy-protection` — prd.md + spec.md 부재. **Action**: `_template/prd.md` + `_template/spec.md` 기반 신규 작성 + 기존 wireframe.html / ui-ux-design.md 에서 마이그레이션. **Evidence**: 각 디렉토리에 wireframe.html 또는 ui-ux-design.md만 존재.

---

## 1. Spec 점검

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | `account-management`, `login-dark-theme`, `privacy-protection` |
| Summary / Motivation 누락 | — |
| Goals 의 P0/P1 / Non-Goals 모호 | — |
| User Journey ↔ CUJ ID prefix 매핑 누락 | — |

### 1-2. spec.md 5섹션 완성도

| Feature | prd.md | spec.md | CUJ 수 | FR/NFR | 비고 |
|---------|--------|---------|--------|--------|------|
| account-deletion | ✓ | ✓ (5섹션) | 26개 | ✓ | — |
| signup-consent | ✓ | ✓ (5섹션) | 25개 | ✓ | — |
| partner-terms-privacy | ✓ | ✓ (5섹션) | 19개 | ✓ | — |
| account-management | ❌ | ❌ | — | — | wireframe.html만 존재 |
| login-dark-theme | ❌ | ❌ | — | — | wireframe.html만 존재 |
| privacy-protection | ❌ | ❌ | — | — | ui-ux-design.md만 존재 |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario ↔ spec.md CUJ ID prefix 불일치 | — |
| spec.md 참조 MDS spec 존재 | ✓ |
| 개발 detail이 spec.md에 포함됨 | — |

**Findings**:
- #2556 — account-management, login-dark-theme, privacy-protection prd.md + spec.md 부재. Severity: P2.

---

## 3. 테스트 현황

### 3-1. app_user

| Layer | 결과 |
|-------|------|
| Widget (account-deletion) | ✓ 4개 (deletion_complete_page, deletion_info_page, deletion_reason_page, deletion_verify_page) |
| Widget (consent) | ✓ (identity_verification_consent_sheet + consent/logic + consent/ui 디렉토리) |
| CUJ integration (signup-consent) | ✓ `signup_consent_test.dart` |
| CUJ integration (account-deletion) | 없음 ❌ (PR #2567 in review) |

### 3-2. app_partner

| Layer | 결과 |
|-------|------|
| Widget (account-deletion) | ✓ 3개 (account_deletion_coordinator, account_deletion_flow, deletion_verify_page) |
| CUJ integration | ✓ `partner_account_deletion_test.dart` (CUJ 1-1만 커버) |

### 3-3. Backend

| Layer | 결과 |
|-------|------|
| Supabase pgTAP (account-deletion) | ✓ 3개 (57_account_deletion_foundation, 58_account_deletion_visibility_rls, 89_account_deletion_immediate_purge) |
| Supabase pgTAP (user_profile) | ✓ (02_users_schema, 12_user_profiles_partner_rls 등) |

**Findings**:
- #2555 — app_user account-deletion CUJ integration test 누락 (26 CUJs). Evidence: `apps/app_user/integration_test/cuj/account/` 내 signup_consent_test.dart만 존재. Severity: P2.

---

## Findings (issue filing)

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|-----------|---------|---------|--------|
| #2555 | 3-1 | app_user account-deletion CUJ integration test 누락 (26 CUJs) | `apps/app_user/integration_test/cuj/account/` — signup_consent_test.dart만 존재 | P2 | S |
| #2556 | 1-1 | account-management + login-dark-theme + privacy-protection prd.md + spec.md 부재 | `docs/features/account/{account-management,login-dark-theme,privacy-protection}/` | P2 | M |

---

## Inputs Consulted

| 입력 | 경로 |
|------|------|
| PRD / spec | `docs/features/account/*/prd.md`, `*/spec.md` |
| BLUEDOC | `docs/features/account/BLUEDOC.md` |
| app_user widget tests | `apps/app_user/test/src/features/account_deletion/`, `apps/app_user/test/src/features/consent/` |
| app_partner widget tests | `apps/app_partner/test/src/features/account_deletion/` |
| CUJ integration tests | `apps/app_user/integration_test/cuj/account/`, `apps/app_partner/integration_test/cuj/account/` |
| Supabase pgTAP | `supabase/tests/database/57_account_deletion_foundation_test.sql` 등 3개 |

---

## Run Metadata

- Agent: swe-sonnet-1
- Duration: ~00:20
- Cycle: 14d (next: 2026-06-01)
- Template version: feature_audit_report_template.md
