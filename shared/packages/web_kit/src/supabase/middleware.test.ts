// updateSession / applySessionCookies 계약 테스트 (#3386)
// @supabase/ssr 의 createServerClient 만 모킹 — 쿠키 어댑터 wiring (setAll 이
// request·최종 response 에 모두 반영되는지) 과 쿠키 이식을 검증한다.
// next/server (NextRequest/NextResponse) 는 실제 구현 사용.
import { createServerClient } from "@supabase/ssr";
import { NextRequest, NextResponse } from "next/server";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { applySessionCookies, updateSession } from "./middleware";

vi.mock("@supabase/ssr", () => ({
  createServerClient: vi.fn(),
}));

const mockedCreateServerClient = vi.mocked(createServerClient);

beforeEach(() => {
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://unit-test.supabase.co");
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY", "anon-key-for-tests");
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
});

describe("updateSession", () => {
  it("getUser 중 setAll 로 갱신된 세션 쿠키가 request 와 최종 response 에 모두 실린다", async () => {
    mockedCreateServerClient.mockImplementation((_url, _key, options) => {
      const client = {
        auth: {
          getUser: async () => {
            // 토큰 refresh 시뮬레이션 — supabase-js 가 이 시점에 setAll 을 부른다.
            options.cookies.setAll?.([
              {
                name: "sb-test-auth",
                value: "refreshed-token",
                options: { path: "/" },
              },
            ]);
            return { data: { user: { id: "user-1" } }, error: null };
          },
        },
      };
      return client as unknown as ReturnType<typeof createServerClient>;
    });

    const request = new NextRequest("http://localhost:3002/my/purchases", {
      headers: { cookie: "sb-test-auth=stale-token" },
    });

    const { user, response } = await updateSession(request);

    expect(user).toEqual({ id: "user-1" });
    // setAll 은 request 쿠키를 먼저 갱신하고 (이후 RSC 가 읽도록)
    expect(request.cookies.get("sb-test-auth")?.value).toBe("refreshed-token");
    // 그 request 로 재생성된 최종 response 에 Set-Cookie 가 실린다
    expect(response.cookies.get("sb-test-auth")?.value).toBe("refreshed-token");
  });

  it("세션이 없으면 user=null, 쿠키 변경 없음", async () => {
    mockedCreateServerClient.mockImplementation(() => {
      const client = {
        auth: {
          getUser: async () => ({ data: { user: null }, error: null }),
        },
      };
      return client as unknown as ReturnType<typeof createServerClient>;
    });

    const request = new NextRequest("http://localhost:3002/events/e1");

    const { user, response } = await updateSession(request);

    expect(user).toBeNull();
    expect(response.cookies.getAll()).toEqual([]);
  });
});

describe("applySessionCookies", () => {
  it("updateSession response 의 세션 쿠키를 redirect response 로 복사한다", () => {
    const from = NextResponse.next();
    from.cookies.set("sb-test-auth", "refreshed-token", { path: "/" });

    const to = NextResponse.redirect("http://localhost:3002/login");
    const result = applySessionCookies(from, to);

    expect(result).toBe(to);
    expect(to.cookies.get("sb-test-auth")?.value).toBe("refreshed-token");
    expect(to.status).toBe(307);
  });
});
