// cuj/discovery/event_feed_test.ts — user-event-feed EF 의 smoke 검증
//
// 본 파일은 framework PoC 첫 샘플. user-event-feed 가:
// - 빈 DB 상태에서 200 + 빈 events 배열 반환
// - 잘못된 sort_by 에 4xx 반환
//
// 더 의미 있는 CUJ 시나리오 (실 이벤트 신청/매칭 funnel) 는 후속 파일.

import { assert, assertEquals } from "jsr:@std/assert@1";
import { suite } from "../../_framework/suite.ts";
import { cujTest } from "../../_framework/cuj_test.ts";

const ctx = suite("discovery/event-feed");

cujTest(ctx, "1-1 user-event-feed returns empty array when no events exist", "single-user", async (ctx) => {
  const user = await ctx.actAs.user("user_test1");
  const res = await user.invoke("user-event-feed", { limit: 20 });

  assertEquals(res.status, 200, `expected 200, got ${res.status}: ${JSON.stringify(res.data)}`);
  const data = res.data as { events?: unknown[] };
  assert(Array.isArray(data.events), `events must be array, got ${typeof data.events}`);
  assertEquals(data.events!.length, 0, "fresh DB should yield 0 events");
});

cujTest(ctx, "1-2 user-event-feed rejects invalid sort_by", "single-user", async (ctx) => {
  const user = await ctx.actAs.user("user_test1");
  const res = await user.invoke("user-event-feed", { limit: 20, sort_by: "bogus" });

  // 400 또는 500 둘 다 허용 — RPC RAISE EXCEPTION 이 어떻게 직렬화되는지 EF 구현 의존
  assert(res.status >= 400, `expected 4xx/5xx for invalid sort_by, got ${res.status}`);
});
