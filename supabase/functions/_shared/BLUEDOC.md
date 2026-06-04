# _shared

모든 Edge Function 이 import 하는 공용 라이브러리. `_` prefix 라 EF entrypoint
아님.

## 이정표

| 항목                                                             | 역할                                                                              |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `edge_function.ts`                                               | `minglitEdgeFunction(handler)` wrapper. manifest env/caller 가드 + logging/Sentry |
| `edge_function_*_test.ts`                                        | wrapper auth/external/deprecation 회귀 테스트                                      |
| `env_keystore.ts`                                                | env-manifest 기반 환경변수 typed 접근                                             |
| `request_utils.ts` / `input_validation.ts` / `response_utils.ts` | request parsing, typed input field validation, CORS/success/error response        |
| `supabase_client.ts`                                             | service/user Supabase client 생성, secret key `apikey`/legacy bearer 헤더 호환    |
| `logger.ts` / `axiom_logger.ts` / `statsig_utils.ts`             | local/Axiom/Statsig observability                                                 |
| `iamport_client.ts` / `portone_client.ts`                        | 결제 외부 client                                                                  |
| `partner_permissions.ts` / `refund_utils.ts` / `worker_utils.ts` | IO 포함 공용 helper                                                               |
| `validation_utils.ts` / `temporal_utils.ts`                      | 입력/시간 helper                                                                  |
| [domains/](domains/BLUEDOC.md)                                   | pure business rule core (`event`, `payment`, `order`)                             |
| [_testing/](_testing/BLUEDOC.md)                                 | L3 handler unit test (`fakeSupabase`, fixtures, `makeCtx`)                        |
| [ai/](ai/)                                                       | AI adapter abstraction                                                            |

## 핵심 컨벤션

- 신규 EF 는 `edge_function.ts` wrapper 와 `auth-manifest.json` 을 사용한다.
- business rule 은 가능하면 `domains/` 로 분리하고 IO helper 와 섞지 않는다.
- `_shared` breaking change 는 모든 EF 영향이므로 전수 회귀가 필요하다.
- 신규 utility 는 동반 `*_test.ts` 를 기본으로 둔다.

## 관련

- [functions/architecture.md](../architecture.md) — EF 레이어 표준
- [edge-function-auth.md](../../../docs/architecture/edge-function-auth.md)
- [edge-functions.md](../../../docs/operations/edge-functions.md)
- [functions/BLUEDOC.md](../BLUEDOC.md)

---

_Reviewed: 2026-06-04 22:22_
