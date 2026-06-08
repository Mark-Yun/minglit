import { createBrowserClient as createSupabaseBrowserClient } from "@supabase/ssr";
import type { Database } from "../types/db";
import { getSupabaseEnv } from "./env";

/**
 * 브라우저(Client Component)용 Supabase 클라이언트.
 * `@supabase/ssr` 의 createBrowserClient 는 기본 싱글턴 — 여러 번 호출해도 안전.
 */
export function createBrowserClient() {
  const { url, anonKey } = getSupabaseEnv();
  return createSupabaseBrowserClient<Database>(url, anonKey);
}
