import {
  createServerClient as createSupabaseServerClient,
  type CookieOptions,
} from "@supabase/ssr";
import type { Database } from "../types/db";
import { getSupabaseEnv } from "./env";

/**
 * `next/headers` 의 `cookies()` 결과와 구조적으로 호환되는 최소 인터페이스.
 * web_kit 이 `next/headers` 를 직접 import 하지 않기 위한 구조 타이핑 —
 * middleware 번들에서 import 되어도 안전하다.
 */
export interface ServerCookieStore {
  getAll(): { name: string; value: string }[];
  set(name: string, value: string, options?: CookieOptions): void;
}

/**
 * Server Component(RSC) / Route Handler / Server Action 용 Supabase 클라이언트.
 *
 * 사용 (RSC):
 * ```ts
 * import { cookies } from "next/headers";
 * const supabase = createServerClient(await cookies());
 * ```
 */
export function createServerClient(cookieStore: ServerCookieStore) {
  const { url, anonKey } = getSupabaseEnv();
  return createSupabaseServerClient<Database>(url, anonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet: { name: string; value: string; options?: CookieOptions }[]) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Server Component 에서 호출되면 쿠키 쓰기가 불가능하다.
          // 세션 갱신은 middleware(createMiddlewareClient)가 담당하므로 무시해도 안전.
        }
      },
    },
  });
}
