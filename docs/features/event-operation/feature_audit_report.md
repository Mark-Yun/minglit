# Feature Audit Report — `event-operation` · `2026-05-18`

## Summary

`event-operation` 카테고리 (feature 6개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P2 — Improvement | 1 | #2564 |
| P3 — Low | 1 | (docs) |

## Action Items by Priority

### P2 — Improvement

- [ ] **#2564** `[3-1]` `event-operation/*` — 양쪽 앱 CUJ integration test 전무. 4개 spec.md feature 모두 미검증. **Action**: `apps/app_user/integration_test/cuj/event-operation/`, `apps/app_partner/integration_test/cuj/event-operation/` 신규 작성.

### P3 — Low

- [ ] `[1-1]` `entry-group-management`, `party-entry-group-management` — prd.md + spec.md 부재 (ui-ux-design.md 구형 포맷). **Action**: 신규 convention 마이그레이션.

## 1. Spec 점검

| Feature | prd.md | spec.md |
|---------|--------|---------|
| entry-group-management | ❌ | ❌ (ui-ux-design.md만) |
| event-now-bar | ✓ | ✓ |
| participation-status-redesign | ✓ | ✓ |
| partner-qr-checkin-ux | ✓ | ✓ |
| party-entry-group-management | ❌ | ❌ (ui-ux-design.md만) |
| ticket-qr-improvement | ✓ | ✓ |

## 3. 테스트 현황

CUJ integration: 양쪽 앱 모두 없음 ❌

## Run Metadata

- Agent: swe-sonnet-1
- Cycle: 14d (next: 2026-06-01)
