# Feature Audit Report — `account` · `2026-05-18`

> 인스펙션 리포트. FRESH_DOC cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다.

## Summary

`account` 카테고리 (feature 6개, spec 보유 3개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | 0 | — |
| P1 — Defect / Gap | 0 | — |
| P2 — Improvement | 2 | #2555, #2556 |
| P3 — Low | 1 | #2587 |

## Action Items by Priority

### P2 — Improvement (다음 스프린트)

- [ ] **#2555** `[3-1]` `account/account-deletion` — app_user CUJ integration test 누락 (26 CUJs 미검증). **Action**: `apps/app_user/integration_test/cuj/account/account_deletion_test.dart` 신규 작성. **Evidence**: 디렉토리 내 `signup_consent_test.dart`만 존재. *(PR #2567 in review)*
- [ ] **#2556** `[1-1]` `account/account-management` + `account/login-dark-theme` + `account/privacy-protection` — prd.md + spec.md 부재. **Action**: `_template/prd.md` + `_template/spec.md` 기반 신규 작성 + 기존 wireframe.html / ui-ux-design.md 에서 마이그레이션. **Evidence**: 각 디렉토리에 wireframe.html 또는 ui-ux-design.md만 존재.

### P3 — Low (여유 시)

- [ ] **#2587** `[2-2]` `account/*` — mds-emulator-render 카탈로그에 account 관련 13 screens 미등록. **Action**: `apps/app_user/integration_test/mds-emulator-render/<screen>/` 패턴 복제로 카탈로그 등록. **Evidence**: `dart run scripts/mds_render_coverage.dart --json` → `uncovered_screens` 에 `account_management_page`, `deletion_*_page`, `signup_consent_page`, `auth_callback_page`, `bank_account_page` 등 포함.

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

## 2. UI 완성도

**Method**:
- MDS spec (디자인 의도): `apps/mds/docs/public/specs/<screen>/state_*.png`
- 앱 render (실 구현): `docs/infra/mds-emulator-render/<screen>/<state>.png`
- 두 PNG 쌍을 시각 비교

### 2-1. MDS spec 완성도

| 점검 | 결과 |
|------|------|
| spec.md CUJ Details 에 언급된 상태가 MDS state PNG 로 존재 | ✓ (주요 screen 모두 커버) |
| MDS state PNG 수가 spec.md CUJ 수에 비해 부족 | — |

관련 MDS spec screen 현황:

| Screen | MDS state PNG 수 |
|--------|-----------------|
| `deletion_reason_page` | 4 |
| `deletion_info_page` | 2 |
| `deletion_verify_page` | 6 |
| `deletion_complete_page` | 2 |
| `account_management_page` | 6 |
| `auth_callback_page` | 3 |
| `bank_account_page` | 6 |
| `signup_consent_page` | 6 |

**Findings**: 없음.

### 2-2. 앱 render coverage

`dart run scripts/mds_render_coverage.dart --json` 기준 (전체 66 MDS screens 중 cataloged 5, screen coverage 7.6%, state coverage 1.1%):

| Screen | Feature | uncovered/incomplete | MDS state PNG 수 |
|--------|---------|---------------------|------------------|
| `account_management_page` | account-management | uncovered | 6 |
| `auth_callback_page` | account-management | uncovered | 3 |
| `bank_account_page` | account-management | uncovered | 6 |
| `blocked_partners_page` | account-management | uncovered | — |
| `deletion_complete_page` | account-deletion | uncovered | 2 |
| `deletion_info_page` | account-deletion | uncovered | 2 |
| `deletion_reason_page` | account-deletion | uncovered | 4 |
| `deletion_verify_page` | account-deletion | uncovered | 6 |
| `signup_consent_page` | signup-consent | uncovered | 6 |
| `privacy_page` | partner-terms-privacy / privacy-protection | uncovered | — |
| `create_verification_page` | privacy-protection | uncovered | — |
| `identity_verification_screen` | privacy-protection | uncovered | — |
| `verification_manage_page` | privacy-protection | uncovered | — |

| 점검 | 결과 |
|------|------|
| mds-emulator-render 미등록 screen (uncovered) | account 관련 13 screens (상기 표) — 카탈로그에 미등록 |
| catalog 됐지만 state 불충분 (incomplete) | — (미등록이라 해당 없음) |
| catalog 됐지만 MDS spec 없음 (orphan) | — |

**Findings**:
- **#2587** — account 카테고리 13 screens 가 `mds-emulator-render` 카탈로그에 미등록. Action: `apps/app_user/integration_test/mds-emulator-render/<screen>/` 패턴 복제. Severity: P3 (인프라 미완성, 점진적 확충).

### 2-3. 앱 render ↔ MDS spec drift (시각 비교)

render PNG 미존재로 시각 비교 불가 (2-2 uncovered 상태). drift 검증은 #2587 완료 후 가능.

| 항목 | 결과 |
|------|------|
| Color drift | 미검증 (render 없음 — #2587 차단) |
| Layout drift | 미검증 (render 없음 — #2587 차단) |
| Typography drift | 미검증 (render 없음 — #2587 차단) |
| 컴포넌트 차이 | 미검증 (render 없음 — #2587 차단) |

**Findings**: 본 카테고리 drift 검증은 #2587 (render coverage) 완료에 의존. 추가 finding 없음.

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
| #2587 | 2-2 | account 카테고리 13 screens `mds-emulator-render` 카탈로그 미등록 | `dart run scripts/mds_render_coverage.dart --json` → `uncovered_screens` | P3 | L |

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

- Agent: swe-sonnet-1 (Section 1, 3) + swe-opus-1 (Section 2 mds-render-coverage data + #2587 filing)
- Duration: ~00:20 (initial) + ~00:10 (Section 2 expansion)
- Cycle: 14d (next: 2026-06-01)
- Template version: feature_audit_report_template.md
