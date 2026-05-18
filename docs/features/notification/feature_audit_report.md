# Feature Audit Report — `notification` · `2026-05-18`

## Summary

`notification` 카테고리 (feature 2개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P2 — Improvement | 0 | — |
| P3 — Low | 1 | (docs) |

## Action Items by Priority

### P3 — Low

- [ ] `[1-1]` `notification/notification-settings` — prd.md + spec.md 부재 (ui-ux-design.md + ui-ux-guide.md 구형 포맷). **Action**: 신규 convention 마이그레이션.

## 1. Spec 점검

| Feature | prd.md | spec.md |
|---------|--------|---------|
| notification-inbox | ✓ | ✓ |
| notification-settings | ❌ | ❌ (구형 포맷) |

## 3. 테스트 현황

| App | CUJ Tests |
|-----|-----------|
| app_user | notification_inbox_test.dart ✓ |
| app_partner | 없음 |

## Run Metadata

- Agent: swe-sonnet-1
- Cycle: 14d (next: 2026-06-01)
