# Specs

`docs/infra/branch-strategy/` 의 추상 명세 모음. 디자인 문서 (branch-flow / dev-pipeline / main-promotion 등) 가 *무엇* 을 어떻게 운영하는지 정의하고, 본 폴더가 그것의 *구현 계약* 을 정의한다. 실제 구현 (YAML, script) 은 별도 PR.

## 배경

design 문서는 운영자 관점 (cadence, role, policy). spec 문서는 구현자 관점 (workflow input/output, branch protection 설정값, refactor 순서). 둘이 섞이면 design 문서가 비대해지고 구현 변경 시 stale 되기 쉬워 분리.

## 이정표

| 문서 | 내용 |
|------|------|
| [workflow-spec.md](./workflow-spec.md) | `.github/workflows/` 의 reusable + entry workflow 의 trigger / input / output / steps / call chain |
| [branch-spec.md](./branch-spec.md) | 각 branch 의 protection rule, required check, merge method, merge queue 구현 설정값 |
| `execution-plan.md` (예정) | 기존 workflow refactor + 신규 구현 + branch 적용 순서 |

## 핵심 컨벤션

- Spec 은 *YAML 디테일 아님*, *계약 정의*. 구현 시 변경되어도 spec 의 의도는 유지
- workflow naming = `<stage>-<action>` (entry) / 명사·동사형 (reusable)
- 모든 reusable 은 `workflow_call` trigger
- spec 변경 시 design 문서와 cross-link 일관 유지 필수

## 관련

- [../BLUEDOC.md](../BLUEDOC.md) — branch-strategy 전체 진입점
- [BLUEDOC convention](../../bluedoc/BLUEDOC.md)

---
_Reviewed: 2026-05-19 09:47_
