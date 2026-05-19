# Feature Audit Report — `event-operation` · `2026-05-18`

> 인스펙션 리포트. FRESH_DOC cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다.

## Summary

`event-operation` 카테고리 (feature 6개, spec 보유 4개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | 0 | — |
| P1 — Defect / Gap | 0 | — |
| P2 — Improvement | 2 | #2564, #2576 |
| P3 — Low | 1 | #2588 |

## Action Items by Priority

### P2 — Improvement (다음 스프린트)

- [ ] **#2564** `[3-1]` `event-operation/*` — CUJ integration test 전무 (4 features, 102 CUJs). **Action**: `apps/app_user/integration_test/cuj/event-operation/` + `apps/app_partner/integration_test/cuj/event-operation/` 신규 작성. **Evidence**: 두 디렉토리 미존재. *(PR #2575 in review: event-now-bar CUJ 1-1/3-2 + partner-qr-checkin CUJ 3-1/3-2 부분 커버)*
- [ ] **#2576** `[1-1]` `event-operation/entry-group-management` + `event-operation/party-entry-group-management` — prd.md + spec.md 부재. **Action**: `_template/prd.md` + `_template/spec.md` 기반 신규 작성. **Evidence**: `docs/features/event-operation/entry-group-management/` — `ui-ux-design.md`만 존재.

### P3 — Low (여유 시)

- [ ] **#2588** `[2-2]` `event-operation/*` — mds-emulator-render 카탈로그에 event-operation 관련 8 screens 미등록. **Action**: `apps/app_user/integration_test/mds-emulator-render/<screen>/` 패턴 복제로 카탈로그 등록. **Evidence**: `dart run scripts/mds_render_coverage.dart --json` → `uncovered_screens` 에 `event_now_bar`, `event_check_in_screen`, `event_checked_in_screen`, `event_bottom_ticket_bar`, `ticket_qr_screen` 등 포함.

---

## 1. Spec 점검

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | `entry-group-management`, `party-entry-group-management` |
| Summary / Motivation 누락 | — |
| Goals 의 P0/P1 / Non-Goals 모호 | — |
| User Journey ↔ CUJ ID prefix 매핑 누락 | — |

### 1-2. spec.md 5섹션 완성도

| Feature | prd.md | spec.md | CUJ 수 | FR/NFR | 비고 |
|---------|--------|---------|--------|--------|------|
| event-now-bar | ✓ | ✓ (5섹션) | 28개 | ✓ | — |
| participation-status-redesign | ✓ | ✓ (5섹션) | 24개 | ✓ | — |
| ticket-qr-improvement | ✓ | ✓ (5섹션) | 23개 | ✓ | — |
| partner-qr-checkin-ux | ✓ | ✓ (5섹션) | 27개 | ✓ | — |
| entry-group-management | ❌ | ❌ | — | — | ui-ux-design.md만 존재 |
| party-entry-group-management | ❌ | ❌ | — | — | ui-ux-design.md만 존재 |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario ↔ spec.md CUJ ID prefix 불일치 | — |
| spec.md 참조 MDS spec 존재 | ✓ (event_now_bar, event_check_in_screen 등 7개 MDS spec 참조) |
| 개발 detail이 spec.md에 포함됨 | — |

**Findings**:
- #2576 — `entry-group-management` + `party-entry-group-management` prd.md + spec.md 부재. Evidence: `docs/features/event-operation/{entry,party-entry}-group-management/`. Severity: P2.

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

| Screen | MDS state PNG 수 | Feature |
|--------|-----------------|---------|
| `event_now_bar` | 7 | event-now-bar |
| `event_check_in_screen` | 4 | partner-qr-checkin-ux |
| `event_checked_in_screen` | 4 | partner-qr-checkin-ux |
| `event_bottom_ticket_bar` | 17 | ticket-qr-improvement |
| `ticket_qr_screen` | 5 | ticket-qr-improvement |

**Findings**: 없음.

### 2-2. 앱 render coverage

`dart run scripts/mds_render_coverage.dart --json` 기준 (전체 66 MDS screens 중 cataloged 5, screen coverage 7.6%, state coverage 1.1%):

| Screen | Feature | uncovered/incomplete | MDS state PNG 수 |
|--------|---------|---------------------|------------------|
| `event_now_bar` | event-now-bar | uncovered | 7 |
| `event_ongoing_banner` | event-now-bar | uncovered | — |
| `event_check_in_screen` | partner-qr-checkin-ux | uncovered | 4 |
| `event_checked_in_screen` | partner-qr-checkin-ux | uncovered | 4 |
| `event_bottom_ticket_bar` | ticket-qr-improvement | uncovered | 17 |
| `ticket_qr_screen` | ticket-qr-improvement | uncovered | 5 |
| `checkin_placeholder_page` | partner-qr-checkin-ux | uncovered | — |
| `recurrence_management_screen` | entry-group-management | uncovered | — |

| 점검 | 결과 |
|------|------|
| mds-emulator-render 미등록 screen (uncovered) | event-operation 관련 8 screens (상기 표) — 카탈로그에 미등록 |
| catalog 됐지만 state 불충분 (incomplete) | — (미등록이라 해당 없음) |
| catalog 됐지만 MDS spec 없음 (orphan) | — |

**Findings**:
- **#2588** — event-operation 카테고리 8 screens 가 `mds-emulator-render` 카탈로그에 미등록. Action: `apps/app_user/integration_test/mds-emulator-render/<screen>/` 패턴 복제. Severity: P3 (인프라 미완성, 점진적 확충).

### 2-3. 앱 render ↔ MDS spec drift (시각 비교)

render PNG 미존재로 시각 비교 불가 (2-2 uncovered 상태). drift 검증은 #2588 완료 후 가능.

| 항목 | 결과 |
|------|------|
| Color drift | 미검증 (render 없음 — #2588 차단) |
| Layout drift | 미검증 (render 없음 — #2588 차단) |
| Typography drift | 미검증 (render 없음 — #2588 차단) |
| 컴포넌트 차이 | 미검증 (render 없음 — #2588 차단) |

**Findings**: 본 카테고리 drift 검증은 #2588 (render coverage) 완료에 의존. 추가 finding 없음.

---

## 3. 테스트 현황

### 3-1. app_user

| Layer | 결과 |
|-------|------|
| Widget (event-now-bar) | ✓ 6개 (event_now_bar_state_provider, event_now_bar, event_now_bottom_sheet, event_now_multi_stack, today_active_events_provider, event_realtime_provider) |
| Widget (ticket-qr) | ✓ 3개 (boarding_pass_card, boarding_pass_status, ticket_selection_sheet) |
| CUJ integration | 없음 ❌ — `apps/app_user/integration_test/cuj/event-operation/` 미존재 (PR #2575 in review) |

### 3-2. app_partner

| Layer | 결과 |
|-------|------|
| Widget (checkin) | ✓ 14개 (summary_card, entry_group_bottom_sheet, entry_group_row, manual_checkin_controller, manual_checkin_sheet, checkin_participant, checkin_stats_controller, entry_group_checkin_stats_controller, scanner_overlay, checkin_smoke 등) |
| CUJ integration | 없음 ❌ — `apps/app_partner/integration_test/cuj/event-operation/` 미존재 (PR #2575 in review) |

### 3-3. Backend

| Layer | 결과 |
|-------|------|
| EF Deno Unit | ✓ `supabase/functions/event-checkin/event_checkin_test.ts` 존재 |
| Supabase pgTAP | ✓ 16+ 테스트 (checkin_rpcs, checkin_group_stats, manual_checkin_rpcs, entry_group_participant_counts, event_pipeline, event_state_machine, matching_trigger, ticket_issuance 등) |

**Findings**:
- #2564 — CUJ integration test 전무. Evidence: `apps/app_*/integration_test/cuj/event-operation/` 미존재. Severity: P2.

---

## Findings (issue filing)

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|-----------|---------|---------|--------|
| #2564 | 3-1 | CUJ integration test 전무 (102 CUJs, 4 features) | `apps/app_*/integration_test/cuj/event-operation/` 미존재 | P2 | M |
| #2576 | 1-1 | entry-group-management + party-entry-group-management prd.md + spec.md 부재 | `docs/features/event-operation/{entry,party-entry}-group-management/` | P2 | M |
| #2588 | 2-2 | event-operation 카테고리 8 screens `mds-emulator-render` 카탈로그 미등록 | `dart run scripts/mds_render_coverage.dart --json` → `uncovered_screens` | P3 | L |

---

## Inputs Consulted

| 입력 | 경로 |
|------|------|
| PRD / spec | `docs/features/event-operation/*/prd.md`, `*/spec.md` |
| BLUEDOC | `docs/features/event-operation/BLUEDOC.md` |
| app_user widget tests | `apps/app_user/test/src/features/home/`, `apps/app_user/test/src/features/ticket/` |
| app_partner widget tests | `apps/app_partner/test/src/features/checkin/` |
| CUJ integration tests | `apps/app_*/integration_test/cuj/` — event-operation 없음 |
| Supabase pgTAP | `supabase/tests/database/99_checkin_*.sql`, `99_manual_checkin_rpcs_test.sql` 등 |
| EF Deno tests | `supabase/functions/event-checkin/event_checkin_test.ts` |

---

## Run Metadata

- Agent: swe-sonnet-1 (Section 1, 3) + swe-opus-1 (Section 2 mds-render-coverage data + #2588 filing)
- Duration: ~00:30 (initial) + ~00:10 (Section 2 expansion)
- Cycle: 14d (next: 2026-06-01)
- Template version: feature_audit_report_template.md
