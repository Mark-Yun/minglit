---
source_url: https://github.com/Mark-Yun/minglit/issues/1998
captured_at: 2026-04-27
issue_number: 1998
state: open
labels: [audit-report, needs-tpm]
author: Mark-Yun
title: "🔍 QA Audit Report — 2026-04-28: 리포지토리 컬럼 SELECT 컨트랙트 갭 — #1937 패턴 재발 위험"
---

# 🔍 QA Audit Report — 2026-04-28: 리포지토리 컬럼 SELECT 컨트랙트 갭 — #1937 패턴 재발 위험

> Issue #1998 · open · created 2026-04-27 · author @Mark-Yun
> https://github.com/Mark-Yun/minglit/issues/1998

## Body

Scheduler: audit-qa-claude-subagents

## 요약 (TL;DR)

지난 일주일 동안 **"존재하지 않는 컬럼을 SELECT" 패턴**이 두 번 P1로 터졌다 (#1566 `created_at` → `event_at`, #1937 `date` → `start_time`). 두 건 모두 머지 후 사후 회귀 가드(`lastSelectColumns` assertion)로 막고 있다 — **반응적 패턴**이다. 같은 클래스의 잠재 버그가 minglit_kit 리포지토리에 **17개 더** 남아있고 가드 없이 prod까지 도달 가능하다.

## 트렌드 근거 (지난 7일)

`audit-report` 이슈 + 최근 closed P1/P2 머지 머지 분석:

| 패턴 | 발생 건수 | 대표 이슈 |
|------|-----------|-----------|
| 리포지토리 silent error 삼킴 | 5건 | #1942 #1948 #1952 #1955 / payment onSuccess |
| EF response.status 미검증 silent fail | 1건 (4 메서드) | #1945 (P1) |
| 존재하지 않는 컬럼 SELECT | **2건** | **#1566, #1937 (둘 다 P1급 정산 영향)** |
| EF cross-feature import 위반 | 3건+ | #1934, AppCoordinator 추출 |

핵심: 기존 위젯/유닛 테스트 풀이 SELECT 컬럼 리스트를 검증하지 않는다. mocktail 기반 mock이 임의 컬럼 호출을 모두 통과시킨다.

## 갭 정량화

`shared/packages/minglit_kit/lib/src/data/repositories` — `select('col1, col2, ...')` 형태의 명시 컬럼 SELECT **19건**:

| 파일 | 명시 컬럼 SELECT 건수 | 회귀 가드 적용 |
|------|----------------------|----------------|
| matching_repository.dart | 4 | ❌ 0 |
| partner_repository.dart | 4 | ❌ 0 |
| social_repository.dart | 3 | ❌ 0 |
| settlement_repository.dart | 2 | ✅ 2 (Fix #1566, #1937) |
| event_repository_queries.dart | 2 | ❌ 0 |
| verification_query_repository.dart | 2 | ❌ 0 |
| account_repository.dart | 1 | ❌ 0 |
| user_repository.dart | 1 | ❌ 0 |

**17개 SELECT가 무방비.** 누구든 컬럼명 오타/리네임을 푸시해도 `flutter test`가 통과한다.

## 제안

### 단기 (1주 내, P2)

1. **`lastSelectColumns` 회귀 가드 일괄 추가** — 위 17건에 대해 각 리포지토리 테스트에 다음 어설션 추가:
   ```dart
   expect(builder.lastSelectColumns, contains('expected_column_name'));
   ```
   - 비용: 메서드당 ~5줄, 합계 < 200 LOC
   - 효과: 컬럼 리네임/오타가 PR CI에서 즉시 fail
   - 인프라 이미 존재 (`MockSupabase.lastSelectColumns` — `shared/packages/minglit_kit/test/helpers/supabase_mock_helpers.dart:92`)

2. **신규 SELECT 도입 시 가드 의무화 가이드** — `docs/qa/test-strategy.md` 에 "explicit column SELECT 추가 시 회귀 가드 필수" 항목 추가.

### 중기 (다음 스프린트, P3)

3. **스키마 introspection 기반 contract test** — Supabase `information_schema.columns` 에서 컬럼 리스트를 한 번 dump → Dart fixture 생성 → 모든 리포지토리 테스트가 fixture와 SELECT 컬럼 교차 검증. pgTAP만으론 잡을 수 없는 클라이언트 측 schema drift를 prod 전에 잡는다.
   - reference: `supabase/tests/database/` 에 이미 50+ pgTAP 테스트 있음. Dart 측에 동일한 신뢰도 부재.

### 직접 처리 가능

이 audit 워커가 단기 항목 (1)을 SWE 워커 도움 없이 SWE 이슈로 분리해서 던지면 처리 가능. 중기 항목 (3)은 architect 협업 필요.

## 기타 시그널 (이번 사이클은 별도 이슈 안 만듬)

- **Silent error 삼킴 패턴**: 지난 7일에 5건 fix됐다. 비슷한 패턴이 더 있을 수 있으나 #1957 (TOCTOU), #1942 (`_computeState`), #1948 (provider) 의 fix PR들이 머지된 직후라 회귀 데이터가 더 쌓일 때까지 관찰. 다음 audit 사이클에서 재평가.
- **CI 신호**: 최근 20개 run 중 dependabot landing-user PR 1건이 일시 실패했지만 Auto Format PR로 수정됨 — flaky 패턴 아님. CI 자체는 건강.

## 다음 액션

- [ ] TPM이 본 리포트를 읽고 단기 (1)을 별도 `needs-swe` 이슈로 분리해 우선순위 P2 부여
- [ ] 중기 (3)은 architect 검토 후 별도 design doc 필요한지 판단

---

**근거 위치**:
- `shared/packages/minglit_kit/test/src/data/repositories/settlement_repository_test.dart:399-427` — 기존 회귀 가드 사례
- `shared/packages/minglit_kit/test/helpers/supabase_mock_helpers.dart:92` — `lastSelectColumns` 인프라
- 최근 7일 closed P1: #1937, #1945, #1941
