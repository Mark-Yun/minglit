# Feature Audit Report — `ticket` · `2026-05-18`

> 인스펙션 리포트. FRESH_DOC cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다.

## Summary

`ticket` 카테고리 (feature 2개, spec 보유 1개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | 0 | — |
| P1 — Defect / Gap | 0 | — |
| P2 — Improvement | 1 | #2580 |
| P3 — Low | 0 | — |

## Action Items by Priority

### P2 — Improvement (다음 스프린트)

- [ ] **#2580** `[1-1]` `ticket/purchase-history-color-hierarchy` — prd.md + spec.md 부재. **Action**: `_template/prd.md` + `_template/spec.md` 기반 신규 작성. **Evidence**: `docs/features/ticket/purchase-history-color-hierarchy/` — wireframe.html만 존재.

---

## 1. Spec 점검

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | `purchase-history-color-hierarchy` |
| Summary / Motivation 누락 | — |
| Goals 의 P0/P1 / Non-Goals 모호 | — |
| User Journey ↔ CUJ ID prefix 매핑 누락 | — |

### 1-2. spec.md 5섹션 완성도

| Feature | prd.md | spec.md | CUJ 수 | FR/NFR | 비고 |
|---------|--------|---------|--------|--------|------|
| my-tickets | ✓ | ✓ (5섹션) | 27개 | ✓ | — |
| purchase-history-color-hierarchy | ❌ | ❌ | — | — | wireframe.html만 존재 |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario ↔ spec.md CUJ ID prefix 불일치 | — |
| spec.md 참조 MDS spec 존재 | ✓ |
| 개발 detail이 spec.md에 포함됨 | — |

**Findings**:
- #2580 — purchase-history-color-hierarchy prd.md + spec.md 부재. Severity: P2.

---

## 3. 테스트 현황

### 3-1. app_user

| Layer | 결과 |
|-------|------|
| Widget (my-tickets) | ✓ 11개 (my_tickets_page, my_tickets_controller, ticket_coordinator, boarding_pass_status, ticket_selection_sheet, boarding_pass_card, ticket_token_service, ticket_wallet_repository, active_event_banners_provider, event_ongoing_banner, event_lifecycle_phase_resolver) |
| CUJ integration | ✓ `my_tickets_test.dart` |

### 3-2. app_partner

| Layer | 결과 |
|-------|------|
| Widget | ✓ 1개 (ticket_controller) |
| CUJ integration | 없음 ❌ |

### 3-3. Backend

| Layer | 결과 |
|-------|------|
| Supabase pgTAP | ✓ 5개 (tickets_entry_group_constraint, ticket_balance_status_type, ticket_issuance, checkin_rpcs, checkin_group_stats) |
| EF Deno Unit | ✓ `user-get-ticket-token` (QR 토큰 발급) |

---

## Findings (issue filing)

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|-----------|---------|---------|--------|
| #2580 | 1-1 | purchase-history-color-hierarchy prd.md + spec.md 부재 | `docs/features/ticket/purchase-history-color-hierarchy/` | P2 | S |

---

## Inputs Consulted

| 입력 | 경로 |
|------|------|
| PRD / spec | `docs/features/ticket/*/prd.md`, `*/spec.md` |
| BLUEDOC | `docs/features/ticket/BLUEDOC.md` |
| app_user widget tests | `apps/app_user/test/src/features/my_tickets/`, `apps/app_user/test/src/features/ticket/`, `apps/app_user/test/src/features/tickets/` |
| app_partner widget tests | `apps/app_partner/test/src/features/ticket/` |
| CUJ integration tests | `apps/app_user/integration_test/cuj/ticket/my_tickets_test.dart` ✓ |
| Supabase pgTAP | `supabase/tests/database/42_ticket_issuance_test.sql` 등 5개 |
| EF | `supabase/functions/user-get-ticket-token/` |

---

## Run Metadata

- Agent: swe-sonnet-1
- Duration: ~00:15
- Cycle: 14d (next: 2026-06-01)
- Template version: feature_audit_report_template.md
