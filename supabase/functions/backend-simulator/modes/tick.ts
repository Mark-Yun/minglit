// v2/modes/tick.ts — Hourly tick wrapper (PoC: 실 EF 연결은 추후)

import type { SupabaseClient } from "@supabase/supabase-js";
import { runCascade, type CascadeResult, type Transport } from "../core/cascade.ts";
import { createPRNG } from "../core/types.ts";
import { defaultRates } from "../params/default.ts";
import { checkAll, type InvariantViolation } from "../invariant/_registry.ts";
import type { WorldSnapshot } from "../core/observable.ts";

// side-effect import — 등록만 발생
import "../action/apply.ts";
import "../invariant/blocking.ts";

export interface TickModeResult {
  cascade: CascadeResult;
  violations: InvariantViolation[];
}

/**
 * Tick 모드: short cascade (default params) + 전체 invariant 검증.
 * 실 EF 연결은 transport 파라미터로 주입 (PoC: mock, 운영: 실 fetch wrapper).
 *
 * PoC 단계: snapshot 은 호출자가 제공 (단일 RPC sim_snapshot 도입은 별도 단계).
 */
export async function runTickMode(opts: {
  supabase: SupabaseClient;
  transport: Transport;
  initialSnapshot: WorldSnapshot;
  ticks?: number;
  seed?: number;
}): Promise<TickModeResult> {
  const cascade = await runCascade({
    actors: [],          // PoC: 호출자가 채움. 본 wrapper 는 cascade 호출 패턴 캡슐화
    initialSnapshot: opts.initialSnapshot,
    rates: defaultRates,
    transport: opts.transport,
    rng: createPRNG(opts.seed ?? Date.now()),
    ticks: opts.ticks ?? 1,
  });

  const violations = await checkAll(opts.supabase);

  return { cascade, violations };
}
