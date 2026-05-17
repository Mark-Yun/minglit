# _payment_integration_tests

결제 도메인 EF chaining 시뮬레이션. 단일 EF unit test 가 못 잡는 **다단계 시나리오** (예: payment-verify → DB 업데이트 → refund) 를 in-process 로 검증.

## 위치

- **DB**: in-memory mock (실 Postgres 없음)
- **EF**: real handler (in-process via `captureServeHandler`)
- **외부 API (PortOne 등)**: route matcher mock

## 파일

- `payment_integration_test.ts` — 결제 happy / fail / refund 시퀀스 chaining
- `payment_edge_cases_test.ts` — 무료 이벤트 / idempotent 결제 / amount 변조 등 edge case

## 패턴

```ts
const handler = await captureServeHandler(new URL("../payment-verify/index.ts", ...));
const { fetchMock } = createFetchMock([
  authRoute,
  { matcher: "...iamport.kr/payments/...", handler: () => jsonResponse(...) },
  { matcher: req => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
    handler: async req => { capturedBody = await req.json(); return jsonResponse({}); } },
]);
await withMockedFetch(fetchMock, () => handler(authenticatedJsonRequest("http://localhost", { ... })));
```

상세 helper: [_test_utils/BLUEDOC.md](../_test_utils/BLUEDOC.md).

## 향후 — `_integration_tests/` 로 흡수 예정

본 디렉토리의 결제 chaining 시나리오는 추후 [`_integration_tests/`](../_integration_tests/BLUEDOC.md) (빈 local Supabase + 외부 mock) 의 cuj/payment/ 그룹으로 마이그 예정. 실 Postgres 사용 시 schema/trigger 회귀까지 가드 가능.

마이그 후 본 디렉토리는 삭제. 그 전까지 두 layer 가 공존 (in-process = 빠름, local Supabase = 깊은 검증).

## 관련

- [_test_utils/BLUEDOC.md](../_test_utils/BLUEDOC.md) — mock_http / fixtures 사용
- [_integration_tests/BLUEDOC.md](../_integration_tests/BLUEDOC.md) — 흡수 대상 layer
- [functions/BLUEDOC.md](../BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
