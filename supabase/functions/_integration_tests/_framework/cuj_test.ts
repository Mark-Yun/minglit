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
 * @param opts.skip  true 면 테스트 ignore (별도 이슈로 분리 필요한 경우)
 */
export function cujTest(
  ctx: Ctx,
  id: string,
  scenario: string,
  fn: (ctx: Ctx) => Promise<void>,
  opts: { skip?: boolean } = {},
): void {
  Deno.test({
    name: `[CUJ ${id}] (scenario=${scenario})`,
    // Fix: env vars 없는 coverage 환경에서 uncaught error 대신 ignore 처리
    ignore: ctx.disabled || opts.skip === true,
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
