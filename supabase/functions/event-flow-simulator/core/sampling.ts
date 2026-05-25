// core/sampling.ts — deterministic actor sampling helpers

import type { PRNG } from "./types.ts";

export function positiveInteger(value: unknown, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return fallback;
  return Math.max(0, Math.floor(value));
}

export function sampleDeterministic<T>(
  items: readonly T[],
  count: number,
  rng: PRNG,
): T[] {
  const limit = Math.max(0, Math.min(Math.floor(count), items.length));
  if (limit === 0) return [];

  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(rng.next() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, limit);
}
