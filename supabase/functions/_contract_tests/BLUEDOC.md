# _contract_tests

Edge Function 응답이 shared JSON schema 와 일치하는지 검증. EF 가 응답 필드를 silently 변경하면 Flutter 클라가 깨지는 걸 PR 시점에 차단.

## 파일

- `contract_test.ts` — 모든 contract 검증을 1 파일에 모음 (Deno.test 블록 다수)

## 검증 대상

`shared/schemas/` 의 schema + sample 쌍:
- `responses/<ef>.json` — JSON schema 정의
- `samples/<ef>_<scenario>.json` — 그 EF 의 예시 응답

테스트 2 종:
1. **Sample ↔ Schema** — sample 파일이 schema 를 만족하는지 (schema 자체 정합성)
2. **EF ↔ Sample/Schema** — EF 가 in-process 호출됐을 때 응답이 sample 과 동등 + schema 만족

## 패턴

```ts
const schema = await loadSchema("payment_verify");
const sample = await loadSample("payment_verify_success");
assertMatchesSchema(sample, schema, "payment_verify_success sample");
```

EF 호출 시 `_test_utils/mock_http.ts` 의 `captureServeHandler` + `createFetchMock` 사용 (in-process). 실 DB 없음.

## 신규 EF contract 추가 절차

1. `shared/schemas/responses/<ef>.json` — schema 작성
2. `shared/schemas/samples/<ef>_success.json` (등) — 예시 응답 작성
3. `contract_test.ts` 에 `Deno.test("contract: sample <ef> matches schema", ...)` 추가
4. (선택) EF in-process 호출 → 응답 검증 테스트 추가

## 관련

- `shared/schemas/` — schema / sample 저장소
- [_test_utils/BLUEDOC.md](../_test_utils/BLUEDOC.md) — schema_validator / mock_http 사용
- [functions/BLUEDOC.md](../BLUEDOC.md)

---
_Reviewed: 2026-05-17 22:32_
