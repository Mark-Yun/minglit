# ef-integration-test — 빠른 가이드

설계는 [architecture.md](./architecture.md), 진입점은 [BLUEDOC.md](./BLUEDOC.md).

## 로컬 실행

```bash
# 1. local Supabase 부팅 (Docker 필요)
supabase start

# 2. 마이그 적용 (db reset 은 모든 데이터 초기화)
supabase db reset --no-seed

# 3. env 캡처
export SUPABASE_URL=$(supabase status -o env | grep API_URL | cut -d= -f2)
export SUPABASE_SERVICE_ROLE_KEY=$(supabase status -o env | grep SERVICE_ROLE_KEY | cut -d= -f2)
export SUPABASE_ANON_KEY=$(supabase status -o env | grep ANON_KEY | cut -d= -f2)
export SIM_USER_PASSWORD=password1234!

# 4. 테스트 실행
cd supabase/functions/_integration_tests
deno test --allow-all cuj/

# 또는 task 사용
deno task test
```

## 신규 CUJ test 추가

1. spec.md 에 CUJ 가 정의돼 있어야 함 (예: `1-1`, `1-2`).
2. `cuj/<category>/<feature>_test.ts` 파일 생성 (없으면).
3. 시나리오가 필요하면 `_framework/scenario.ts` 에 키 추가.
4. cujTest 블록 작성:

```ts
import { suite } from "../../_framework/suite.ts";
import { cujTest } from "../../_framework/cuj_test.ts";

const ctx = suite("category/feature");

cujTest(ctx, "1-1 <한 줄 설명>", "scenario-name", async (ctx) => {
  const user = await ctx.actAs.user("user_test1");
  const res = await user.invoke("apply-event", { ... });
  assertEquals(res.status, 200);
  // ... assertion
});
```

## 디버깅

- 로컬 Supabase 로그: `supabase logs functions`
- EF 별 로그 stream: `supabase logs functions <ef-name> --follow`
- DB 확인: `psql postgresql://postgres:postgres@127.0.0.1:54322/postgres`
