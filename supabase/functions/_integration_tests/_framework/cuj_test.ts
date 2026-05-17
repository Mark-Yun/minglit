// _framework/cuj_test.ts — Deno.test wrapper

import type { Ctx } from "./suite.ts";
import { applyScenario } from "./scenario.ts";

/**
 * cujTest — Deno.test 래퍼. scenario 시드 + 실 EF 호출 + assertion.
 *
 * @param ctx        suite() 반환 ctx
 * @param id         CUJ ID + 짧은 설명 (예: "1-1 user gets empty feed")
 * @param scenario   _framework/scenario.ts 의 키 (예: "fresh", "single-user")
 * @param fn         실제 테스트 본문 — (ctx) => Promise<void>
 */
export function cujTest(
  ctx: Ctx,
  id: string,
  scenario: string,
  fn: (ctx: Ctx) => Promise<void>,
): void {
  Deno.test({
    name: `[CUJ ${id}] (scenario=${scenario})`,
    async fn() {
      await applyScenario(scenario, ctx.db);
      try {
        await fn(ctx);
      } catch (err) {
        // 실패 시 디버깅 도움 출력
        console.error(`\n[CUJ ${id}] FAILED — scenario=${scenario}`);
        throw err;
      }
    },
  });
}
