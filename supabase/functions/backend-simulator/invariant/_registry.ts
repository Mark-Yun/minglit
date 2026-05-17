// v2/invariant/_registry.ts — Cross-EF 비즈니스 규칙 가드

import type { SupabaseClient } from "@supabase/supabase-js";

export interface InvariantViolation {
  invariant: string;
  details: unknown;
}

export interface Invariant {
  name: string;
  description: string;
  /** 위반 발견 시 violation 객체 배열 반환. 빈 배열 = 통과 */
  check(supabase: SupabaseClient): Promise<InvariantViolation[]>;
}

const registry = new Map<string, Invariant>();

export function registerInvariant(inv: Invariant): void {
  registry.set(inv.name, inv);
}

export function getInvariant(name: string): Invariant | undefined {
  return registry.get(name);
}

export function allInvariants(): Invariant[] {
  return [...registry.values()];
}

export async function checkAll(
  supabase: SupabaseClient,
): Promise<InvariantViolation[]> {
  const results = await Promise.all(allInvariants().map((inv) => inv.check(supabase)));
  return results.flat();
}

/** 테스트용 */
export function clearInvariants(): void {
  registry.clear();
}
