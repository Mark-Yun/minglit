# Feature Audit Report — `event` · `2026-05-18`

> 인스펙션 리포트. FRESH_DOC cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다.

## Summary

`event` 카테고리 (feature 6개, spec 보유 4개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | 0 | — |
| P1 — Defect / Gap | 0 | — |
| P2 — Improvement | 2 | #2563, #2579 |
| P3 — Low | 0 | — |

## Action Items by Priority

### P2 — Improvement (다음 스프린트)

- [ ] **#2563** `[3-1]` `event/*` — app_user CUJ integration test 없음 (event-edit-cancel, partner-dashboard, recurring-events, refund-policy-v2 미검증). **Action**: `apps/app_user/integration_test/cuj/event/` 신규 작성. **Evidence**: 디렉토리 미존재. *(app_partner: event_edit_cancel_test.dart 1개 존재)*
- [ ] **#2579** `[1-1]` `event/event-detail-empty-state` + `event/partner-detail-event-card` — prd.md + spec.md 부재. **Action**: `_template/prd.md` + `_template/spec.md` 기반 신규 작성. **Evidence**: 두 디렉토리 내 파일 없음.

---

## 1. Spec 점검

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | `event-detail-empty-state`, `partner-detail-event-card` |
| Summary / Motivation 누락 | — |
| Goals 의 P0/P1 / Non-Goals 모호 | — |
| User Journey ↔ CUJ ID prefix 매핑 누락 | — |

### 1-2. spec.md 5섹션 완성도

| Feature | prd.md | spec.md | CUJ 수 | FR/NFR | 비고 |
|---------|--------|---------|--------|--------|------|
| event-edit-cancel | ✓ | ✓ (5섹션) | 24개 | ✓ | — |
| partner-dashboard | ✓ | ✓ (5섹션) | 34개 | ✓ | — |
| recurring-events | ✓ | ✓ (5섹션) | 26개 | ✓ | — |
| refund-policy-v2 | ✓ | ✓ (5섹션) | 29개 | ✓ | — |
| event-detail-empty-state | ❌ | ❌ | — | — | 디렉토리 내 파일 없음 |
| partner-detail-event-card | ❌ | ❌ | — | — | 디렉토리 내 파일 없음 |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario ↔ spec.md CUJ ID prefix 불일치 | — |
| spec.md 참조 MDS spec 존재 | ✓ |
| 개발 detail이 spec.md에 포함됨 | — |

**Findings**:
- #2579 — event-detail-empty-state + partner-detail-event-card prd.md + spec.md 부재. Severity: P2.

---

## 2. UI 완성도

**Method**:
- MDS spec (디자인 의도): `apps/mds/docs/public/specs/<screen>/state_*.png`
- 앱 render (실 구현): `docs/infra/mds-emulator-render/<screen>/<state>.png`
- 두 PNG 쌍을 시각 비교

### 2-1. MDS spec 완성도

| Screen | MDS state PNG 수 | 비고 |
|--------|-----------------|------|
| `event_detail_page` | 6 | ✓ |
| `event_matching_screen` | 7 | ✓ |
| `event_matching_results_screen` | 0 | ❌ PNG 없음 (TBD spec 상태 반영) |
| `partner_event_detail_page` | 6 | ✓ |
| `tag_event_list_page` | 4 | ✓ |

**Findings**: `event_matching_results_screen` MDS spec PNG 미생성 (spec 자체가 TBD 상태 — `#2411` 참조).

### 2-2. 앱 render coverage

| 점검 | 결과 |
|------|------|
| mds-emulator-render `_registry.dart` 미등록 screen (uncovered) | 모든 event screen — `docs/infra/mds-emulator-render/`에 home_page 외 미등록 |
| catalog 됐지만 state 불충분 (incomplete) | — (미등록이라 해당 없음) |
| catalog 됐지만 MDS spec 없음 (orphan) | — |

**Findings**: 없음 (emulator render 미등록은 인프라 미완성 상태).

### 2-3. 앱 render ↔ MDS spec drift (시각 비교)

render PNG 미존재로 시각 비교 불가 (2-2 uncovered 상태).

| 항목 | 결과 |
|------|------|
| Color drift | — (render 없음) |
| Layout drift | — (render 없음) |
| Typography drift | — (render 없음) |
| 컴포넌트 차이 | — (render 없음) |

**Findings**: 없음.

---

## 3. 테스트 현황

### 3-1. app_user

| Layer | 결과 |
|-------|------|
| Widget | ✓ 23개 (admission/, detail/, logic/, matching/, ui/ 하위 폴더) |
| CUJ integration | 없음 ❌ — `apps/app_user/integration_test/cuj/event/` 미존재 |

### 3-2. app_partner

| Layer | 결과 |
|-------|------|
| Widget | ✓ 18개 (create/, detail/, edit/, review/, widgets/ 하위 폴더) |
| CUJ integration | ✓ `event_edit_cancel_test.dart` (1개 — 나머지 3 features 미검증) |

### 3-3. Backend

| Layer | 결과 |
|-------|------|
| Supabase pgTAP | ✓ 8개 (events_schema, events_rls, event_notification_trigger, event_state_machine, apply_event, event_pipeline, event_participants_retention, event_applications_with_user_rpc) |
| EF Deno Unit | event-flow-simulator, event-matching, apply-event, event-checkin, partner-manage-event, user-event-feed, _integration_tests/cuj/event/ |

**Findings**:
- #2563 — app_user event CUJ integration test 없음 (113 CUJs 미검증). Evidence: `apps/app_user/integration_test/cuj/event/` 미존재. Severity: P2.

---

## Findings (issue filing)

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|-----------|---------|---------|--------|
| #2563 | 3-1 | app_user event CUJ integration test 없음 (113 CUJs) | `apps/app_user/integration_test/cuj/event/` 미존재 | P2 | L |
| #2579 | 1-1 | event-detail-empty-state + partner-detail-event-card prd.md + spec.md 부재 | `docs/features/event/{event-detail-empty-state,partner-detail-event-card}/` | P2 | M |

---

## Inputs Consulted

| 입력 | 경로 |
|------|------|
| PRD / spec | `docs/features/event/*/prd.md`, `*/spec.md` |
| BLUEDOC | `docs/features/event/BLUEDOC.md` |
| app_user widget tests | `apps/app_user/test/src/features/event/` (23개) |
| app_partner widget tests | `apps/app_partner/test/src/features/event/` (18개) |
| CUJ integration tests | `apps/app_user/integration_test/cuj/event/` 없음, `apps/app_partner/integration_test/cuj/event/event_edit_cancel_test.dart` |
| Supabase pgTAP | `supabase/tests/database/04_events_schema_test.sql` 등 8개 |
| EF | `supabase/functions/event-matching/`, `apply-event/`, `event-checkin/` 등 |

---

## Run Metadata

- Agent: swe-sonnet-1
- Duration: ~00:20
- Cycle: 14d (next: 2026-06-01)
- Template version: feature_audit_report_template.md
