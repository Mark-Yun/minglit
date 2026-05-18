# Feature Audit Report — `admin` · `2026-05-18`

> 인스펙션 리포트. `FRESH_DOC` cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다. 본 문서는 **감사 추적(audit trail)** 이며, 직접 편집하지 않는다.

## Summary

`admin` 카테고리 (feature 2개) 인스펙션 결과:

| Severity | Count | Issues |
|---|---|---|
| P0 — Critical | `0` | — |
| P1 — Defect / Gap | `0` | — |
| P2 — Improvement | `1` | `#2559` |
| P3 — Low | `0` | — |

---

## Action Items by Priority

### P0 — Critical (즉시 처리)

_해당 없음_

### P1 — Defect / Gap (이번 스프린트)

_해당 없음_

### P2 — Improvement (다음 스프린트)

- [ ] **#2559** `[2-1]` `admin/admin-dashboard` — Next.js admin 앱이 본 모노레포 `apps/` 디렉토리에 없음. 구현 상태 불명확 (별도 repo vs 미착수). P0 CUJ 15개 구현 확인 필요. **Action**: 구현 상태 확인 후 로드맵 수립 또는 별도 repo 링크 문서화. **Evidence**: `apps/` 디렉토리에 `admin` 없음, `prd.md`/`spec.md`는 완성.

### P3 — Low (여유 시)

_해당 없음_

---

## 1. Spec 점검

**Method**: `docs/features/admin/<feature>/` 내 `prd.md` + `spec.md` 를 `BLUEDOC.md` 5섹션 컨벤션 + canonical example 과 대조.

### 1-1. PRD 누락 / 부족

| 점검 | 결과 |
|------|------|
| prd.md 부재 features | 없음 — admin-dashboard ✓, statistics-tools ✓ |
| Summary / Motivation 누락 | 없음 |
| Goals P0/P1 / Non-Goals 모호 | 없음 |
| User Journey ↔ CUJ ID 매핑 누락 | 없음 |

### 1-2. spec.md 5섹션 완성도

| 점검 | 결과 |
|------|------|
| spec.md 부재 features | 없음 |
| 5섹션 구조 미적용 | 없음 — 양쪽 모두 CUJs / FR / NFR / Edge / Open Q 완성 |
| CUJs 테이블 행 부족 | 없음 — admin-dashboard 32개, statistics-tools 14개 |
| NFR 측정 불가능 | 없음 — p75/p95/분위수 명시 |
| Open Questions 1주+ 방치 | admin-dashboard 8개, statistics-tools 6개 — 결정 상태 추적 권장 |

### 1-3. PRD ↔ spec.md ↔ MDS 트레이스

| 점검 | 결과 |
|------|------|
| PRD Scenario ↔ spec.md CUJ ID 불일치 | 없음 |
| spec.md 참조 MDS state PNG 부재 | admin-dashboard — web app이므로 MDS spec 해당없음 |
| 개발 detail 이 spec.md 에 포함됨 | 없음 |

**Findings**:
- `#2559` — admin-dashboard 앱 모노레포 미존재. Evidence: `apps/` 디렉토리. Severity: `P2`.

---

## 2. UI 완성도

**Method**: admin-dashboard 는 Next.js web app (Flutter MDS 해당없음). statistics-tools 는 외부 서비스 (Statsig + Metabase).

### 2-1. MDS spec 완성도

_해당 없음 — admin 카테고리는 Flutter MDS 범위 외_

### 2-2. 앱 render coverage

_해당 없음_

### 2-3. 앱 render ↔ MDS spec drift

_해당 없음_

**Findings**: 해당 없음

---

## 3. 테스트 현황

### 3-1. app_user

_해당 없음 — admin 기능은 app_user 범위 외_

### 3-2. app_partner

_해당 없음 — admin 기능은 app_partner 범위 외_

### 3-3. Backend

| Layer | Path | 점검 항목 | 결과 |
|------|------|-----------|------|
| EF Deno Unit | `supabase/functions/metrics-alert/` | metrics-alert EF | `metrics_alert_test.ts` ✓ (ALERT_LABELS 4종 + fallback 테스트) |
| Supabase pgTAP | `supabase/tests/database/52_analytics_infrastructure_test.sql` | analytics schema + analytics_reader role | ✓ (8 plan: schema/role/tables/privileges) |
| Admin dashboard DB | — | admin 전용 RLS/Trigger | 검사 미수행 (앱 부재로 연결 쿼리 불명) |

### 3-4. CI 실패 패턴

- 최근 7일 admin 관련 CI 실패: 없음

**Findings**: 해당 없음 (metrics-alert + analytics schema 모두 커버됨)

---

## Findings (issue filing)

| ID | 분류 | 한 줄 설명 | Evidence | Severity | Effort |
|----|------|----------|----------|----------|--------|
| `#2559` | `2-1` | admin-dashboard Next.js 앱 모노레포 미존재 — 구현 상태 불명확 | `apps/` — admin 디렉토리 없음 | `P2` | `L` |

---

## Inputs Consulted

| 입력 | 경로 / 도구 |
|------|-----------|
| PRD / spec | `docs/features/admin/{admin-dashboard,statistics-tools}/{prd,spec}.md` |
| BLUEDOC | `docs/features/admin/BLUEDOC.md` |
| apps 디렉토리 | `apps/` — admin 앱 부재 확인 |
| EF Deno test | `supabase/functions/metrics-alert/metrics_alert_test.ts` |
| Supabase pgTAP | `supabase/tests/database/52_analytics_infrastructure_test.sql` |
| Recent activity | `gh pr list --search updated:>7d` (admin 키워드) |

---

## Run Metadata

- Agent: `swe-sonnet-1`
- Duration: `~20min`
- Cycle: `14d` (next: `2026-06-01`)
- Template version: `c6bd89a1e`
