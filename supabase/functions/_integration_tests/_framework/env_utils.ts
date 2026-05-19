// _framework/env_utils.ts — Supabase env vars 정규화

/** trim + 양쪽 큰따옴표 제거. supabase status -o env 의 quoted output 대응. */
export function stripQuotes(s: string): string {
  return s.trim().replace(/^"(.*)"$/, "$1");
}

/** supabase-js 2.105+ validateSupabaseUrl 이 127.0.0.1 거부 → localhost 로 정규화. */
export function normalizeSupabaseUrl(s: string): string {
  return stripQuotes(s).replace("127.0.0.1", "localhost");
}
