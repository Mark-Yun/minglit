# _coverage

Deno EF 단위 테스트 (`functions/<ef>/*_test.ts`) 의 coverage 측정 + 자동 리포트 저장소.

## 측정 대상

- `functions/*/*.ts` (`_*` prefix 제외) — EF 진입점 + 내부 모듈
- 측정 도구: `deno coverage` (내장)
- 출력: LCOV → markdown 변환 (`coverage.ts`)

## 두 종류 리포트

| 종류 | 워크플로우 | 출력 |
|---|---|---|
| **Periodic snapshot** (dev 기준) | `monitor-deno-coverage.yml` (on push to dev, `supabase/functions/**`) | `_coverage/coverage-report.md` 자동 갱신 (commit `[skip ci]`) |
| **PR diff coverage** (변경 라인 한정) | `pr-gate.yml` 의 `test-edge-functions` 잡 — diff-cover ≥90% gate | PR sticky comment + 미만 시 PR 차단 |

## 파일

- `coverage.ts` — Deno script: `deno coverage --lcov` → 본 폴더의 markdown 생성
- `coverage-report.md` — 자동 갱신 (수동 편집 금지 — 다음 push 에 덮어씀)

## 로컬 실행

```bash
cd supabase/functions
deno test --allow-all --coverage=cov_profile
deno coverage --lcov cov_profile > coverage.lcov
deno run --allow-read --allow-write _coverage/coverage.ts \
  --lcov=coverage.lcov \
  --out=_coverage/coverage-report.md
```

## Gate 정책

- **PR-time**: diff-cover ≥90% 변경 라인 — 미만 시 PR fail (회귀 코드 차단)
- **Periodic**: 전체 EF coverage 보고만, gate 없음 (시계열 추세 가시화)

## 관련

- [functions/BLUEDOC.md](../BLUEDOC.md) — EF 진입점
- [_test_utils/BLUEDOC.md](../_test_utils/BLUEDOC.md) — 테스트 mock/fixture 인벤토리
