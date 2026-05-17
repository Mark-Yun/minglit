// v2/core/trace.ts — Event sourcing log

import type { Action, ActorId } from "./types.ts";

export interface TraceEntry {
  tick: number;
  actorId: ActorId;
  action: Action;
  status: number;                       // EF response status (0 = system action)
  ok: boolean;
  error?: string;
}

export type Trace = TraceEntry[];

/** 위반/실패 step 의 직전 N 개 추출 — 디버깅용 */
export function lastN(trace: Trace, n: number): Trace {
  return trace.slice(-n);
}
