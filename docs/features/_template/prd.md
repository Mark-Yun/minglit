# PRD: `<Feature Name>`

> **사용법**: 본 파일을 `docs/features/<category>/<feature>/prd.md` 로 복사 후 `<placeholder>` 를 모두 채운다. canonical 예시: [`docs/features/account/signup-consent/prd.md`](../account/signup-consent/prd.md). 컨벤션: [`docs/features/BLUEDOC.md`](../BLUEDOC.md).

## Summary

`<1-2 문장: feature 가 무엇이고 왜 만드는지>`

## Motivation / Problem to Solve

- `<문제 1 — 사용자 / 비즈니스 / 법무 / 기술 부채 등 출처 명시>`
- `<문제 2>`
- `<근거: 감사 보고서 / 사용자 피드백 / 지표 — 가능하면 issue 번호나 데이터 source>`

## Goals

### Target Users

- `<사용자 유형>`: `<해당 상황 / 사용 맥락>`
- `<2차 사용자가 있으면>`: `<상황>`

### Key Goals

- **P0**: `<반드시 달성해야 할 결과>`
- **P0**: `<...>`
- **P1**: `<추가 달성하면 좋은 결과>`

### Non-Goals

- `<명시적으로 본 PR 범위에서 제외>`
- `<왜 제외했는지 한 줄>`

## Product Principles

1. **`<원칙명>`**: `<설명 — 의사결정 시 적용 룰>`
2. **`<원칙명>`**: `<...>`

## Technical Approach

- **화면**: `<신규 / 수정 화면 목록>`
- **저장**: `<테이블 / 컬럼 — 데이터 정의 수준만, 스키마 SQL X>`
- **외부 의존성**: `<API / 라이브러리 / 플러그인>`
- **가드 / 정책**: `<라우터 가드, RLS, 권한>`

## User Journey

### Scenario 1: `<시나리오 이름>` (CUJ 1-x)

`<1-2 문장: 시나리오의 사용자 흐름. spec.md 의 CUJ 1-1, 1-2, ... 로 분해됨>`

### Scenario 2: `<시나리오 이름>` (CUJ 2-x)

`<...>`

## Data Flow

### Scenario 1

`<단계별 흐름 — 트리거 → 화면/페이지 → 저장/네트워크 → 결과>`

### Scenario 2

`<...>`

## KPIs / Success Metrics

- **`<지표명>`**: `<목표값 — 측정 방법 명시>`
- **`<지표명>`**: `<baseline / target>`

## Launch Strategy

`<선택사항: A/B 실험, 점진적 출시, feature flag, 등>`

## Legal Basis

`<선택: 관련 법령 / 정책 / 회사 정책 — 법적 제약이 있는 feature 만>`

| 근거 | 내용 |
|------|------|
| `<법률 / 정책>` | `<요구사항>` |

## References

- `<레퍼런스 앱>`: `<벤치마킹한 패턴 한 줄>`
- `<관련 문서 / 이전 PR>`
