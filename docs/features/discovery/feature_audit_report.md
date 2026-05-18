# Feature Audit Report — `discovery` · `2026-05-18`

> 인스펙션 리포트. FRESH_DOC cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다.

## Summary

`discovery` 카테고리 (feature 2개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | 0 | — |
| P1 — Defect / Gap | 0 | — |
| P2 — Improvement | 1 | #2561 |
| P3 — Low | 0 | — |

## Action Items by Priority

### P2 — Improvement

- [ ] **#2561** `[3-1]` `discovery/tag-discovery` + `discovery/trust-badge` — CUJ integration test 전무. 26 CUJs (P0 8개 포함) 미검증. widget test는 tag-discovery 6개 존재. **Action**: `apps/app_user/integration_test/cuj/discovery/` 신규 작성. **Evidence**: `apps/app_user/integration_test/cuj/` — discovery 디렉토리 없음.

## 1. Spec 점검

### 1-1. PRD / spec.md 완성도

| Feature | prd.md | spec.md | CUJ 수 | FR/NFR |
|---------|--------|---------|--------|--------|
| tag-discovery | ✓ | ✓ (5섹션) | 15개 | 13 FR, 5 NFR |
| trust-badge | ✓ | ✓ (5섹션) | 11개 | 16 FR, 4 NFR |

### 1-3. MDS 트레이스

| 화면 | MDS spec |
|------|----------|
| `tag_event_list_page` | ✓ |
| `home_page`, `search_page` | ✓ |
| `verification_manage_page`, `identity_verification_screen`, `create_verification_page` | ✓ |
| `trust_badge` / `trust_sheet` 위젯 | 디자인 TODO (spec에 명시됨) |

## 3. 테스트 현황

### 3-1. app_user

| Layer | 결과 |
|-------|------|
| Widget (tag-discovery) | ✓ 6개 (chip_bar, trending, providers×2, controller, list_page) |
| CUJ integration | 없음 ❌ (discovery 디렉토리 미존재) |

### 3-3. Backend pgTAP

`60_tag_discovery_schema_test.sql`, `63_tag_sensitive_filter_test.sql`, `66_tag_usage_retention_test.sql`, `67_tag_monthly_rls_test.sql`, `70_ai_extract_tags_migration_test.sql` — 5개 ✓

## Findings

| ID | 분류 | 설명 | Severity |
|----|------|------|----------|
| #2561 | 3-1 | discovery CUJ integration test 전무 (26 CUJs) | P2 |

## Run Metadata

- Agent: swe-sonnet-1
- Cycle: 14d (next: 2026-06-01)
- Template version: c6bd89a1e
