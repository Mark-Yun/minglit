# _shared/_testing

EF handler **L3 unit test** 인프라. `handler(req, ctx)` 를 fake supabase 와 함께 직접 호출.

## 왜 필요?

EF 의 70%+ 가 IO (DB / RPC / 외부 API). pure 추출 (L2) 만으로는 coverage 한계 ~35%.
`fakeSupabase` 가 builder chain 을 **실제로 실행** 하고 terminal 만 scripted response 로 받음 →
Deno coverage 가 EF 의 DB 라인까지 trace → unit test 만으로 60%+ 도달 가능.

## 파일

| 파일 | 역할 |
|---|---|
| `fake_supabase.ts` | chainable fake `SupabaseClient` (builder chain 실행 + scripted resolve) |
| `fake_supabase_test.ts` | fake 자체 sanity test |
| `fake_ef_context.ts` | `makeCtx({ supabase, userId, ... })` — EFContext factory |
| `handler_runner.ts` | `runHandler(handler, { body, ctx })` |
| `http_helpers.ts` | `makeRequest` / `readJson` |
| `fixtures/` | row builder (`buildApplication` / `buildEvent` / `buildTicket` / `buildUserProfile`) |
| `mod.ts` | public re-exports |

## 표준 패턴

```ts
// supabase/functions/<ef>/index_test.ts
import { handler } from "./index.ts";
import {
  buildApplication,
  fakeSupabase,
  makeCtx,
  runHandler,
} from "../_shared/_testing/mod.ts";

Deno.test("<ef> :: <분기 description>", async () => {
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildApplication({ status: "pending" }) })
    .on("event_applications", "delete", { error: null });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
});
```

## fidelity 결정 (시니어급)

| 기능 | 구현 | 이유 |
|---|---|---|
| Builder chain `.from().select().eq()…` | 모두 실행, terminal 만 scripted | coverage trace 극대화 |
| `.single()` / `.maybeSingle()` | array → 첫 원소, primitive → 그대로 | Supabase 동작 일치 |
| `.insert()` / `.update()` / `.delete()` | scripted, payload + filter capture | 호출 시퀀스 단언 |
| `.rpc(name, args)` | scripted | 분기 cover |
| Postgres error code | `error.code` 그대로 전달 | 에러 분기 가드 |
| RLS / Realtime / Storage | ❌ | L4 integration 책임 |
| Strict order matching | ❌ | refactor 내성 |

## 스크립트 매칭 규칙

`(table, op)` 일치 시 등록 순서대로 소비. `match` 함수로 fine-grained 필터 가능 (filter 값 검사 등).
한 script 는 1회 소비. 같은 (table, op) 가 여러 번 호출되면 script 도 여러 개 등록.

## Strict / Non-strict

- `fakeSupabase()` — strict: 매칭 안 되는 query 는 throw (test 의도 명확)
- `fakeSupabase({ strict: false })` — 매칭 안 되면 `{ data: null, error: null }` 반환 (legacy code 용)

기본 strict 권장.

## 관련

- [_shared/BLUEDOC.md](../BLUEDOC.md)
- [functions/BLUEDOC.md](../../BLUEDOC.md)
- [_integration_tests/BLUEDOC.md](../../_integration_tests/BLUEDOC.md) — L4 CUJ tests (real Supabase)

---
_Reviewed: 2026-05-18 06:30_