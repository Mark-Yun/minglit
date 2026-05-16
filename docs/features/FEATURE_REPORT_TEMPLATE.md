# Feature Report — `<category>` · `<YYYY-MM-DD>`

> 인스펙션 리포트. `FRESH_DOC` cycle 트리거로 에이전트가 본 절차를 수행하고 발견 사항을 GitHub Issue 로 파일링한다. 본 문서는 **감사 추적(audit trail)** 이며, 직접 편집하지 않는다.

## Summary

`<카테고리>` 카테고리 인스펙션 결과 P1 결함 `<N>` 건, 탐지 룰 보강 `<M>` 건, P2 개선 제안 `<K>` 건 파일링.

| Severity | Count | Issues |
|---|---|---|
| P1 — Defect | `<N>` | `<#aaa> <#bbb>` |
| P1 — Detection gap | `<M>` | `<#ccc> <#ddd>` |
| P2 — Improvement | `<K>` | `<#eee> <#fff>` |

---

## P1 — Defects

**Method**. `docs/spec-walker/screenshot/<flow>/` 의 step PNG 와 `apps/mds/docs/public/specs/<screen>/state_*.png` 를 짝지어 시각/동작 drift 점검. 동시에 최근 CI 실행에서 본 카테고리 코드 경로의 실패/플레이키 검토.

**Findings**.

- `<#issue>` — `<one-line finding>`. Evidence: `<spec-walk path 또는 MDS state png 또는 test name>`.
- `<#issue>` — ...

**Coverage taken**.

| 비교한 spec-walk step | 매칭된 MDS state PNG | drift 발견 |
|---|---|---|
| `<N>` | `<M>` | `<K>` |

---

## P1 — Detection Gaps

**Method**. 본 카테고리 spec.md 가 다루는 화면/상호작용을 enumerate 하고, (a) spec-walker `flows/` 에 매핑이 없는 항목, (b) 코드 변경 빈도 대비 단위/widget/E2E 테스트가 부족한 영역 식별. 이런 누락은 P1 인스펙션 자체의 신뢰도를 낮추므로 P1 으로 다룬다.

**Findings**.

- `<#issue>` — `<누락된 spec-walk flow 또는 테스트 영역>`. Why it matters: `<없으면 다음 cycle 에 어떤 결함을 놓치는지>`.
- `<#issue>` — ...

**Coverage taken**.

| 누락된 spec-walk path | 테스트 보강 권고 영역 |
|---|---|
| `<N>` | `<M>` |

---

## P2 — Improvements

**Method**. 최근 30일의 본 카테고리 관련 이슈/PR 트렌드, 리뷰 코멘트 테마, 코드 hot spot, 워크플로우 비효율 지점에서 (a) production UX 개선, (b) 개발 리소스 효율화, (c) 워크플로우 자동화 강화 제안 도출.

**Findings**.

- `<#issue>` — `<제안 한 줄>`. Impact: `<low/med/high>`. Effort: `<S/M/L>`.
- `<#issue>` — ...

---

## Inputs Consulted

- **spec-walk**: `docs/spec-walker/screenshot/{<flows>}/` — `<N>` flow × `<M>` step (latest walk: `<YYYY-MM-DD>`)
- **MDS specs**: `apps/mds/docs/public/specs/{<screens>}/` — `<N>` screen / `<M>` state PNG
- **Tests reviewed**:
  - Flutter unit/widget/golden — `apps/app_{user,partner}/test/` (golden via alchemist)
  - Flutter integration — `apps/app_user/test/integration/`
  - Patrol E2E (weekly) — `patrol_test/`, last run `<YYYY-MM-DD>`: `<status>`
  - pgTAP — `supabase/tests/database/`, `<count>` tests
  - Edge functions (Deno) — `supabase/functions/*/*_test.ts`, `<count>` tests
- **카테고리 spec**: `docs/features/<category>/<feature>/spec.md` × `<N>`
- **Recent activity**: 최근 30일 본 카테고리 관련 이슈 `<count>` / PR `<count>`

---

## Run Metadata

- Agent: `<runner id>`
- Duration: `<HH:MM>`
- Cycle: `<Nd>` (next: `<YYYY-MM-DD>`)
- Template version: `<git sha>`
