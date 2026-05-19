// v2/core/cascade.ts — Stochastic Cascade 엔진

import type { Action, Actor, PRNG } from "./types.ts";
import { projectForPartner, projectForUser, type WorldSnapshot } from "./observable.ts";
import type { Trace, TraceEntry } from "./trace.ts";
import { userPolicy } from "../policy/user.ts";
import { partnerPolicy } from "../policy/partner.ts";
import type { Rates } from "../params/default.ts";

/**
 * Transport = action → 실 EF 호출 (또는 mock).
 * 단위 테스트는 in-memory mock 으로 격리.
 */
export interface Transport {
  execute(action: Action): Promise<{
    ok: boolean;
    status: number;
    data?: unknown;
    error?: string;
  }>;
}

export interface CascadeConfig {
  actors: Actor[];
  initialSnapshot: WorldSnapshot;
  rates: Rates;
  transport: Transport;
  rng: PRNG;
  /** 시뮬할 tick 수 */
  ticks: number;
  /** 각 tick 후 snapshot 갱신 콜백 (실 운영: 재조회 RPC). 미제공 시 snapshot 변경 X */
  refreshSnapshot?: (current: WorldSnapshot, trace: Trace) => Promise<WorldSnapshot> | WorldSnapshot;
  /** EF 호출 후 throttle delay (ms). Supabase 의 per-trace rate limit (Fix #2545) 회피용. 기본 0 = 즉시. 실 운영 권장 200~400ms */
  delayBetweenCallsMs?: number;
}

export interface CascadeResult {
  trace: Trace;
  finalSnapshot: WorldSnapshot;
}

export async function runCascade(config: CascadeConfig): Promise<CascadeResult> {
  const trace: Trace = [];
  let snapshot = config.initialSnapshot;

  for (let tick = 0; tick < config.ticks; tick++) {
    for (const actor of config.actors) {
      const observable = actor.role === "user"
        ? projectForUser(snapshot, actor.id)
        : projectForPartner(snapshot, actor.id);

      const policy = actor.role === "user" ? userPolicy : partnerPolicy;
      const actorRng = config.rng.split();
      const action = policy(actor.id, observable, config.rates, actorRng);
      if (!action) continue;

      const result = await config.transport.execute(action);
      const entry: TraceEntry = {
        tick,
        actorId: actor.id,
        action,
        status: result.status,
        ok: result.ok,
      };
      if (result.error) entry.error = result.error;
      trace.push(entry);

      // Fix #2545: Supabase per-trace rate limit 회피. EF 호출 후만 sleep (skip-action 시는 즉시 다음).
      if (config.delayBetweenCallsMs && config.delayBetweenCallsMs > 0) {
        await new Promise((r) => setTimeout(r, config.delayBetweenCallsMs));
      }
    }

    if (config.refreshSnapshot) {
      snapshot = await config.refreshSnapshot(snapshot, trace);
    }
  }

  return { trace, finalSnapshot: snapshot };
}
