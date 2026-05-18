# Feature Audit Report — `event` · `2026-05-18`

## Summary

`event` 카테고리 (feature 6개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P2 — Improvement | 2 | #2563, (docs) |
| P3 — Low | 1 | (docs) |

## Action Items by Priority

### P2 — Improvement

- [ ] **#2563** `[3-1]` `event/*` — app_user event CUJ integration test 없음 (4개 feature, spec.md CUJ 수십 개). app_partner는 event_edit_cancel_test.dart 1개만 존재. **Action**: `apps/app_user/integration_test/cuj/event/` 신규 작성.

### P3 — Low

- [ ] `[1-1]` `event/event-detail-empty-state`, `event/partner-detail-event-card` — prd.md + spec.md 부재 (wireframe.html만 존재). **Action**: 신규 convention 마이그레이션 또는 소규모 feature로 Non-Goal 처리.

## 1. Spec 점검

| Feature | prd.md | spec.md |
|---------|--------|---------|
| event-detail-empty-state | ❌ | ❌ (wireframe만) |
| event-edit-cancel | ✓ | ✓ |
| partner-dashboard | ✓ | ✓ |
| partner-detail-event-card | ❌ | ❌ (wireframe만) |
| recurring-events | ✓ | ✓ |
| refund-policy-v2 | ✓ | ✓ |

## 3. 테스트 현황

| App | CUJ Tests | 커버 Feature |
|-----|-----------|-------------|
| app_user | **없음** ❌ | — |
| app_partner | event_edit_cancel_test.dart ✓ | event-edit-cancel 1개만 |

## Findings

| ID | 분류 | 설명 | Severity |
|----|------|------|----------|
| #2563 | 3-1 | app_user event CUJ integration test 없음 | P2 |
| — | 1-1 | event-detail-empty-state, partner-detail-event-card prd/spec 부재 | P3 |

## Run Metadata

- Agent: swe-sonnet-1
- Cycle: 14d (next: 2026-06-01)
