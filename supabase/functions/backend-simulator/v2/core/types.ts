// v2/core/types.ts — Stochastic Cascade 핵심 타입

export type ActorRole = "user" | "partner" | "system";

export type ActorId = string;

export interface Actor {
  id: ActorId;
  role: ActorRole;
}

/** Action = 1개의 EF 호출 (또는 system 행위) */
export interface Action {
  type: string;                         // e.g., "user_apply"
  actorId: ActorId;
  payload: Record<string, unknown>;
  ef?: string;                          // EF endpoint name (system action 은 없음)
}

/**
 * Splittable PRNG — 액터별 독립 시드 + 전체 reproducible.
 * splitmix64 같은 알고리즘 권장. 본 PoC 는 단순 LCG 로 시작.
 */
export interface PRNG {
  /** [0, 1) 범위 sample */
  next(): number;
  /** 독립 substream 생성 (액터별 격리용) */
  split(): PRNG;
}

/** 결정론적 단순 LCG PRNG — PoC 용. splittable interface 만 만족하면 교체 가능 */
export function createPRNG(seed: number): PRNG {
  let state = seed >>> 0;
  return {
    next() {
      state = (state * 1664525 + 1013904223) >>> 0;
      return state / 0xFFFFFFFF;
    },
    split() {
      return createPRNG(state ^ 0xDEADBEEF);
    },
  };
}
