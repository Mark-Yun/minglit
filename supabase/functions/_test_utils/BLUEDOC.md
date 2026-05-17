# _test_utils

EF 단위 테스트 + in-process 통합 테스트가 사용하는 공용 mock / fixture / validator.

## 파일

| 파일 | 역할 |
|---|---|
| `mock_supabase_client.ts` | `createMockSupabaseClient(handlers)` — tables / rpcs / auth 응답 모킹. unit test 의 DB stub |
| `mock_http.ts` | `captureServeHandler` + `createFetchMock` + `withMockedFetch` + `withEnv` + `withNoIntervals` — outbound fetch 차단 + EF handler in-process 실행 |
| `mock_custom_auth_pass.ts` / `mock_custom_auth_fail.ts` | minglitEdgeFunction wrapper 의 custom auth fixture |
| `fixtures.ts` | 공용 sample 페이로드 (mockPaidPayment, mockOrder, mockQueueUpdateMessage 등) |
| `schema_validator.ts` | `assertMatchesSchema` — JSON schema 일치 가드 (`_contract_tests` 가 사용) |
| `std_server_stub.ts` | Deno std http server 의 minimal stub (테스트 격리) |

## 사용 패턴

### Unit test (단일 EF)
```ts
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
const mock = createMockSupabaseClient({ tables: { event_applications: { select: () => ({ data: [...] }) } } });
```

### In-process chaining (`_payment_integration_tests/`)
```ts
import { captureServeHandler, createFetchMock, withMockedFetch } from "../_test_utils/mock_http.ts";
const handler = await captureServeHandler(new URL("../<ef>/index.ts", import.meta.url));
const { fetchMock } = createFetchMock([authRoute, { matcher: ..., handler: ... }]);
await withMockedFetch(fetchMock, () => handler(request));
```

### Contract test (`_contract_tests/`)
```ts
import { assertMatchesSchema } from "../_test_utils/schema_validator.ts";
assertMatchesSchema(sample, schema);
```

## 변경 정책

각 EF 의 `*_test.ts` 가 import 함. signature 변경 시 모든 caller 영향 — `git grep` 으로 사용처 확인 후.

## 관련

- [functions/BLUEDOC.md](../BLUEDOC.md) — EF 진입점
- 사용처: 각 EF 의 `*_test.ts`, `_payment_integration_tests/`, `_contract_tests/`

---
_Reviewed: 2026-05-17 22:32_
