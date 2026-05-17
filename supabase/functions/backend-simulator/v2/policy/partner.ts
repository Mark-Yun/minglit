// v2/policy/partner.ts — Partner actor 정책 (stub — PoC 단계에선 미구현)

import type { Action, ActorId, PRNG } from "../core/types.ts";
import type { ObservableState } from "../core/observable.ts";
import type { Rates } from "../params/default.ts";

/**
 * Partner 정책 — user.ts 와 동일한 가중 sampling 패턴 예정.
 * PoC 단계: 등록된 partner 액션 없으므로 null 반환.
 */
export function partnerPolicy(
  _actorId: ActorId,
  _state: ObservableState,
  _rates: Rates,
  _rng: PRNG,
): Action | null {
  return null;
}
