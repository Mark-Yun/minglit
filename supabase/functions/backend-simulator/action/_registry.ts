// v2/action/_registry.ts — Action 정의 등록

import type { Action, ActorRole, PRNG } from "../core/types.ts";
import type { ObservableState } from "../core/observable.ts";

export interface ActionDef {
  type: string;
  role: ActorRole;
  ef?: string;
  /** 이 액션이 현재 observable state 에서 실행 가능한지 */
  canExecute: (state: ObservableState) => boolean;
  /** EF 호출 payload */
  buildPayload: (state: ObservableState, rng: PRNG) => Record<string, unknown>;
}

const registry = new Map<string, ActionDef>();

export function registerAction(def: ActionDef): void {
  registry.set(def.type, def);
}

export function getAction(type: string): ActionDef | undefined {
  return registry.get(type);
}

export function getActionsForRole(role: ActorRole): ActionDef[] {
  return [...registry.values()].filter((a) => a.role === role);
}

export function getAvailableActions(role: ActorRole, state: ObservableState): ActionDef[] {
  return getActionsForRole(role).filter((a) => a.canExecute(state));
}

export function buildAction(
  def: ActionDef,
  actorId: string,
  state: ObservableState,
  rng: PRNG,
): Action {
  return {
    type: def.type,
    actorId,
    payload: def.buildPayload(state, rng),
    ef: def.ef,
  };
}

/** 테스트용 — 등록된 액션 초기화 */
export function clearRegistry(): void {
  registry.clear();
}
