import {
  createServerClient as createSupabaseServerClient,
  type CookieOptions,
} from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "../types/db";
import { getSupabaseEnv } from "./env";

export interface MiddlewareClient {
  supabase: ReturnType<typeof createSupabaseServerClient<Database>>;
  /** setAll 시점에 재생성되므로 getter — 항상 마지막 response 를 읽는다. */
  readonly response: NextResponse;
}

/**
 * Next.js middleware 용 Supabase 클라이언트 + 쿠키 동기화 response.
 *
 * 사용 (middleware.ts):
 * ```ts
 * const { supabase, response } = createMiddlewareClient(request);
 * const { data } = await supabase.auth.getUser(); // 세션 갱신 트리거 — 반드시 호출
 * return response;
 * ```
 *
 * 주의: `response` 는 `supabase.auth.*` 호출 이후에 읽어야
 * 갱신된 세션 쿠키가 포함된다 (getter 로 최신 인스턴스 반환).
 */
export function createMiddlewareClient(request: NextRequest): MiddlewareClient {
  const { url, anonKey } = getSupabaseEnv();

  let response = NextResponse.next({ request });

  const supabase = createSupabaseServerClient<Database>(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet: { name: string; value: string; options?: CookieOptions }[]) {
        for (const { name, value } of cookiesToSet) {
          request.cookies.set(name, value);
        }
        response = NextResponse.next({ request });
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options);
        }
      },
    },
  });

  return {
    supabase,
    get response() {
      return response;
    },
  };
}
