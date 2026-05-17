# Spec: `<Feature Name>`

> **참조**
> - PRD: [prd.md](./prd.md)
> - MDS specs (UI 디자인 + state PNG): 본 feature 가 사용하는 화면 모두 나열
>   - [`<screen_name_1>`](../../../../apps/mds/docs/public/specs/<screen_name_1>/) — `<용도>`
>   - [`<screen_name_2>`](../../../../apps/mds/docs/public/specs/<screen_name_2>/) — `<용도>` (없으면 디자인 TODO 표기)
> - Wireframe (있으면): [wireframe.html](./wireframe.html)
>
> **사용법**: 본 파일을 `docs/features/<category>/<feature>/spec.md` 로 복사 후 `<placeholder>` 를 모두 채운다. canonical 예시: [`docs/features/account/signup-consent/spec.md`](../account/signup-consent/spec.md). 컨벤션: [`docs/features/BLUEDOC.md`](../BLUEDOC.md).

## CUJs

> CUJ ID 컨벤션: `<scenario>-<cuj>` (예: `1-1` = PRD Scenario 1 의 첫 CUJ). 새 CUJ 추가 시 본 테이블 row 추가 + `apps/app_*/integration_test/cuj/<category>/<feature>_test.dart` 의 `cujGroup` 블록 추가.

| ID  | Priority | CUJ Name | Details | FR | NFR |
|-----|----------|----------|---------|----|----|
| 1-1 | P0 | `<CUJ 한 줄>` | • `<step 1>`<br>• `<step 2>`<br>• `<결과>` | FR-1, FR-2 | NFR-1 |
| 1-2 | P0 | `<...>` | `<...>` | FR-3 | NFR-1 |
| 2-1 | P1 | `<...>` | `<...>` | FR-4, FR-5 | NFR-2 |

## Functional Requirements

> 제품 행동 정의 — DB schema SQL / Provider 이름 / Repository 메서드 시그니처 같은 dev detail 은 제외 (코드/migration 이 SSoT).

- **FR-1**: `<요구사항 한 줄 — 측정 가능한 행동>`
- **FR-2**: `<...>`
- **FR-3**: `<...>`

## Non-Functional Requirements

> 측정 가능해야 함 — "빨라야 함" 금지. 환경 + 분위수 명시 (예: "에뮬레이터 baseline, p50 200ms 이내").

- **NFR-1**: `<성능 / 응답 시간 — 측정 환경 + p50/p99>`
- **NFR-2**: `<접근성 / 보안 / 안정성>`

## Edge Cases

| CUJ ID | 케이스 | 기대 동작 |
|--------|--------|----------|
| 1-1 | `<상황 — 네트워크 끊김 / 입력 오류 / 동시성 등>` | `<기대 동작 — retry / 차단 / 에러 메시지>` |
| 1-1 | `<...>` | `<...>` |
| 2-1 | `<...>` | `<...>` |

## Open Questions

> 결정 못한 항목 — 1주 이상 방치 시 명시적으로 결정 또는 Non-Goal 로 이동.

- [ ] `<결정 필요한 항목 — 옵션 A vs B>`
- [ ] `<...>`

---

## 화면 구성 (참고)

> dev 가 아닌 product/UX detail 만. wireframe.html 이 있으면 그쪽 우선 참조.

### 화면 1: `<Screen Name>`

**표시 시점**: `<언제 진입하는지>`

**레이아웃**: `<ascii art / 설명 / 위젯 트리 — 위젯 클래스 이름은 X>`

### 데이터 정의 (참고)

| 항목 | key | 설명 |
|------|-----|------|
| `<항목 이름>` | `<DB 또는 API key>` | `<의미>` |
