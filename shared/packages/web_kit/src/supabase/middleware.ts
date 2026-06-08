import {
  createServerClient as createSupabaseServerClient,
  type CookieOptions,
} from "@supabase/ssr";
import type { User } from "@supabase/supabase-js";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "../types/db";
import { getSupabaseEnv } from "./env";

export interface UpdateSessionResult {
  /** 세션이 없으면 null — 보호 라우트 분기는 이 값으로 한다. */
  user: User | null;
  /**
   * 갱신된 세션 쿠키가 이미 실린 최종 response.
   * `auth.getUser()` 가 완료된 뒤 생성되므로 그대로 반환해도 안전하다.
   */
  response: NextResponse;
  supabase: ReturnType<typeof createSupabaseServerClient<Database>>;
}

/**
 * Next.js middleware 용 세션 갱신 — 한 번에 끝내는 canonical 패턴.
 *
 * 내부에서 `auth.getUser()` 까지 호출한 뒤 최종 response 를 반환하므로
 * "auth 호출 전에 response 를 읽는" 오용이 구조적으로 불가능하다.
 *
 * 사용 (middleware.ts):
 * ```ts
 * const { user, response } = await updateSession(request);
 * if (!user && isProtectedPath(request.nextUrl.pathname)) {
 *   const redirect = NextResponse.redirect(new URL("/login", request.url));
 *   return applySessionCookies(response, redirect);
 * }
 * return response;
 * ```
 */
export async function updateSession(
  request: NextRequest,
): Promise<UpdateSessionResult> {
  const { url, anonKey } = getSupabaseEnv();

  let response = NextResponse.next({ request });

  const supabase = createSupabaseServerClient<Database>(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(
        cookiesToSet: { name: string; value: string; options?: CookieOptions }[],
      ) {
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

  // 세션 갱신 트리거 — setAll 이 여기서 실행되어 response 가 최종본이 된다.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return { user, response, supabase };
}

/**
 * updateSession 의 response 가 아닌 다른 response (redirect 등) 를 반환할 때,
 * 갱신된 세션 쿠키를 옮겨 싣는다. 빠뜨리면 refresh 토큰이 유실된다.
 */
export function applySessionCookies(
  from: NextResponse,
  to: NextResponse,
): NextResponse {
  for (const cookie of from.cookies.getAll()) {
    to.cookies.set(cookie);
  }
  return to;
}
