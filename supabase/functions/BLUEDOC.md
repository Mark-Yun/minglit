# Supabase Edge Functions

minglit 의 backend API 진입점. 60+ EF 와 공용 `_shared/`, 테스트 유틸을
포함한다.

## 이정표

| 항목                                                                   | 역할                                                             |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [architecture.md](architecture.md)                                     | EF 표준 레이어 (`index/input/service/domain/RPC`) 와 테스트 전략 |
| [auth-manifest.json](auth-manifest.json)                               | EF 별 env/caller 선언. wrapper 가 런타임 가드                    |
| [_shared/](./_shared/BLUEDOC.md)                                       | wrapper, HTTP, DB client, logger, pure domain core               |
| [_test_utils/](./_test_utils/BLUEDOC.md)                               | HTTP mock, fixture, schema validator                             |
| [_contract_tests/](./_contract_tests/BLUEDOC.md)                       | EF 응답 JSON schema contract                                     |
| [_integration_tests/](./_integration_tests/BLUEDOC.md)                 | local Supabase + 외부 mock integration/CUJ                       |
| [_payment_integration_tests/](./_payment_integration_tests/BLUEDOC.md) | 결제 chaining 시뮬. 추후 `_integration_tests/` 흡수              |
| [event-flow-simulator/](./event-flow-simulator/BLUEDOC.md)             | 이벤트 lifecycle funnel 시뮬레이터                               |
| [user-create-order/](./user-create-order/BLUEDOC.md)                   | 이벤트 신청/주문 생성 EF                                         |
| [payment-verify/](./payment-verify/BLUEDOC.md)                         | PortOne 결제 검증/승인 EF                                        |

## 핵심 컨벤션

- 신규/핵심 EF 는 `minglitEdgeFunction` + `auth-manifest.json` 를 반드시
  사용한다.
- 복잡한 EF 는 `index.ts` 를 얇게 두고 `input.ts` / `service.ts` 로 분리한다.
- 비즈니스 규칙은 `_shared/domains/<domain>` 의 pure 함수와 mock 없는 unit test
  로 검증한다.
- 원자성이 필요한 write 는 EF service 가 아니라 Postgres RPC boundary 로 옮긴다.
- 모든 신규 EF 는 `<ef-name>_test.ts` 또는 `index_test.ts`, 필요 시 response
  contract 를 추가한다.

## 관련

- [edge-function-auth.md](../../docs/architecture/edge-function-auth.md)
- [edge-functions.md](../../docs/operations/edge-functions.md)
- [test-strategy.md](../../docs/qa/test-strategy.md)
- [BLUEDOC convention](../../docs/infra/bluedoc/BLUEDOC.md)

---

_Reviewed: 2026-05-24 00:00_
