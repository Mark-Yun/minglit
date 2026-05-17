// policy/partner.ts — Partner actor 정책 (user 와 동일한 가중 sampling)

import type { Action, ActorId, PRNG } from "../core/types.ts";
import type { ObservableState } from "../core/observable.ts";
import { buildAction, getAvailableActions } from "../action/_registry.ts";
import type { Rates } from "../params/default.ts";

export function partnerPolicy(
  actorId: ActorId,
  state: ObservableState,
  rates: Rates,
  rng: PRNG,
): Action | null {
  const candidates = getAvailableActions("partner", state);
  if (candidates.length === 0) return null;

  const weighted = candidates.map((def) => ({
    def,
    weight: rates.partner[def.type] ?? 0.1,
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
  return buildAction(weighted[weighted.length - 1].def, actorId, state, rng);
}
