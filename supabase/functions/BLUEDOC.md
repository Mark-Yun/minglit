# Supabase Edge Functions

minglit 의 backend API 진입점. 60+ EF (user / partner / system / public) + 5 underscore-prefix 공용 디렉토리.

## 디렉토리 분류

### 공용 (`_` prefix — EF 아님)

| 디렉토리 | 역할 |
|---|---|
| [_shared/](./_shared/BLUEDOC.md) | 모든 EF 가 import 하는 공용 라이브러리 (wrapper / logger / HTTP / DB / 외부 client / 도메인 helper) |
| [_test_utils/](./_test_utils/BLUEDOC.md) | 테스트 공용 mock 및 fixture (mock_supabase / mock_http / schema_validator 등) |
| [_payment_integration_tests/](./_payment_integration_tests/BLUEDOC.md) | 결제 도메인 EF chaining 시뮬 (in-process, mock 전체). 추후 `_integration_tests/` 로 흡수 예정 |
| [_contract_tests/](./_contract_tests/BLUEDOC.md) | EF 응답 ↔ shared JSON schema 일치 가드 |
| [_integration_tests/](./_integration_tests/BLUEDOC.md) | 빈 local Supabase + 외부 mock 으로 실 schema/trigger/RLS contract 검증 (Layer 5.5) |

### EF (60+)

도메인별 (auth-manifest.json 의 `callers` 기준):

| 카테고리 | 예 |
|---|---|
| **user** (33) — JWT 인증, 유저/파트너 호출 | apply-event, payment-verify, partner-manage-party, user-event-feed ... |
| **system** (15) — pg_cron / worker 호출 | notification-worker, settlement-register-transfers, recurrence-cron ... |
| **public** (4) — 인증 없음 (dev 전용 + health) | event-flow-simulator, dev-mock-portone, dev-seed, health |
| **external** (1) — 외부 콜백 | payment-webhook (PortOne) |

특수 EF: [event-flow-simulator/](./event-flow-simulator/BLUEDOC.md) — 이벤트 라이프사이클 funnel 시뮬레이터 (Stochastic Cascade 모델).

## auth-manifest.json

각 EF 의 `envs` (어느 환경에서 동작) + `callers` (누가 호출) + 설명 선언. `_shared/edge_function.ts` 의 `minglitEdgeFunction` wrapper 가 호출 시 manifest 기반 가드 적용. 상세: [docs/architecture/edge-function-auth.md](../../docs/architecture/edge-function-auth.md).

## 신규 EF 추가 절차

1. `<ef-name>/index.ts` + `deno.json` 생성
2. `minglitEdgeFunction` wrapper 사용 (`_shared/edge_function.ts`)
3. `auth-manifest.json` 에 entry 추가 (envs / callers / description)
4. `<ef-name>/<ef_name>_test.ts` 단위 테스트 (`_test_utils/` 활용)
5. `supabase/config.toml` 의 `[functions.<ef-name>]` 자동 생성 또는 수동 등록
6. (선택) `shared/schemas/responses/<ef>.json` + `_contract_tests` 항목 추가

## 관련 컨벤션

- [BLUEDOC convention](../../docs/infra/bluedoc/BLUEDOC.md)
- [edge-function-auth.md](../../docs/architecture/edge-function-auth.md) — minglitEdgeFunction wrapper + manifest
- [edge-functions.md](../../docs/operations/edge-functions.md) — 디버깅 / Axiom / Sentry
- [test-strategy.md](../../docs/qa/test-strategy.md) — 7-Layer test taxonomy
