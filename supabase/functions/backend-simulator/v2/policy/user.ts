// v2/policy/user.ts — User actor 정책

import type { Action, ActorId, PRNG } from "../core/types.ts";
import type { ObservableState } from "../core/observable.ts";
import { buildAction, getAvailableActions } from "../action/_registry.ts";
import type { Rates } from "../params/default.ts";

/**
 * User 정책: 현재 observable state 에서 실행 가능한 액션들을 rates 가중치로 sampling.
 * 가능한 액션 없으면 null (해당 tick 에 행위 안 함).
 */
export function userPolicy(
  actorId: ActorId,
  state: ObservableState,
  rates: Rates,
  rng: PRNG,
): Action | null {
  const candidates = getAvailableActions("user", state);
  if (candidates.length === 0) return null;

  const weighted = candidates.map((def) => ({
    def,
    weight: rates.user[def.type] ?? 0.1,
  }));
  const totalWeight = weighted.reduce((s, w) => s + w.weight, 0);
  if (totalWeight <= 0) return null;

  let r = rng.next() * totalWeight;
  for (const { def, weight } of weighted) {
    r -= weight;
    if (r <= 0) {
      return buildAction(def, actorId, state, rng);
    }
  }
  // 부동소수 누적 오차 대비 fallback
  return buildAction(weighted[weighted.length - 1].def, actorId, state, rng);
}
