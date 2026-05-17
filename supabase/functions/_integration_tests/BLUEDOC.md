# ef-integration-test

빈 local Supabase + 외부 API mock 으로 EF 의 실 schema/trigger/RLS contract 를 PR-time 에 검증하는 통합 테스트 레이어.

## 위치 — 기존 test layer 사이의 빈 칸

| Layer | 무엇을 검증 | 비용 |
|---|---|---|
| 5 Deno unit (`*_test.ts` + mock supabase) | EF 내부 로직 | 빠름 |
| **(신규) ef-integration-test** | **실 Postgres/trigger/RLS contract** | **중** |
| 7 event-flow-simulator (cascade) | 확률 분포 cross-EF emerge (dev 환경) | 무거움 |

## 폴더 구조

```
_integration_tests/
├── BLUEDOC.md / README.md / architecture.md
├── _framework/                  ← local_supabase / reset / seed / invoke / mock_external
└── cuj/<category>/<feature>_test.ts
    예: cuj/account/signup_consent_test.ts
        cuj/event/refund_policy_v2_test.ts
```

- **1 feature = 1 파일**, 다수 CUJ 가 한 파일에 `Deno.test("<cuj-id> ...", ...)` 블록
- 폴더명 dash → 파일명 underscore (`signup-consent` → `signup_consent_test.ts`)
- CUJ ID 는 [features/BLUEDOC.md](../../../docs/features/BLUEDOC.md) 의 `<scenario>-<cuj>` 컨벤션 (예: `1-1`, `1-2`)

## 핵심 원리

1. **빈 local DB** — `supabase start` + `supabase db reset --no-seed` → 마이그만 적용된 깨끗한 Postgres
2. **외부 API mock** — PortOne 은 `dev-mock-portone` 로 redirect, Statsig 은 key 미설정으로 no-op
3. **실 EF runtime** — Supabase CLI 의 Edge Runtime → 실 schema/trigger/RLS 동작
4. **CUJ ID 추적** — spec.md 의 CUJs 표 ID 를 Deno.test 이름에 prefix → coverage notification 가 매핑
5. **CUJ binary 검증** — 각 cujTest = 1 CUJ 충족 여부 통과/실패. assertion 작성 자유 (helper 는 필요 시 자연 발생, tier 설계 X)

## 인접 layer 와의 관계

- `_payment_integration_tests/` — in-process EF 체이닝 + 전체 mock (실 DB 없음). 다른 layer, 공존
- `event-flow-simulator/` — Layer 7 cascade. dev 환경 대상 long-running. 책임 분리

## 형제 문서

- [architecture.md](./architecture.md) — 설계 상세 / CI yaml / 외부 mock 전략 (예정)
- [README.md](./README.md) — 로컬 실행 빠른 가이드 (예정)

## 관련 컨벤션

- [BLUEDOC](../../../docs/infra/bluedoc/BLUEDOC.md), [features/BLUEDOC.md](../../../docs/features/BLUEDOC.md) (PRD + spec.md + CUJ ID), [test-strategy.md](../../../docs/qa/test-strategy.md), [edge-functions.md](../../../docs/operations/edge-functions.md)

---
_Reviewed: 2026-05-17 22:32_
