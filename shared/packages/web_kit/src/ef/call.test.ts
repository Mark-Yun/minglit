// callEdgeFunction 런타임 계약 테스트 (#3386)
// - fetch 는 vi.stubGlobal 모킹, supabase 는 call.ts 가 쓰는 표면(auth.getSession)만 스텁.
// - 에러 envelope 는 supabase/functions/_shared/response_utils.ts 의
//   errorResponse 형식 { error, details? } 를 그대로 재현한다.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "./call";
import { MinglitError } from "./errors";
import { applyEvent } from "./functions/apply-event";

const SUPABASE_URL = "https://unit-test.supabase.co";
const ANON_KEY = "anon-key-for-tests";
const USER_TOKEN = "user-access-token";

function sessionSource(accessToken: string | null = USER_TOKEN): SessionSource {
  return {
    auth: {
      getSession: async () => ({
        data: {
          session: accessToken ? { access_token: accessToken } : null,
        },
      }),
    },
  };
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** fetch 를 모킹하고 mock 함수를 돌려준다. */
function stubFetch(...responses: Response[]) {
  const mock = vi.fn<typeof fetch>();
  for (const response of responses) mock.mockResolvedValueOnce(response);
  vi.stubGlobal("fetch", mock);
  return mock;
}

function lastRequest(mock: ReturnType<typeof stubFetch>) {
  const call = mock.mock.calls.at(-1);
  if (!call) throw new Error("fetch was not called");
  const [input, init] = call;
  return { url: String(input), init: init ?? {}, headers: (init?.headers ?? {}) as Record<string, string> };
}

async function expectMinglitError(promise: Promise<unknown>): Promise<MinglitError> {
  try {
    await promise;
  } catch (error) {
    expect(error).toBeInstanceOf(MinglitError);
    return error as MinglitError;
  }
  throw new Error("expected MinglitError to be thrown");
}

beforeEach(() => {
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", SUPABASE_URL);
  vi.stubEnv("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY", ANON_KEY);
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("callEdgeFunction — 요청 형성", () => {
  it("EF URL 로 POST 하고 세션 토큰을 Bearer 로, anon key 를 apikey 로 첨부한다", async () => {
    const mock = stubFetch(jsonResponse({ ok: true }));

    await callEdgeFunction(sessionSource(), "user-create-order", {
      event_id: "e1",
    });

    const { url, init, headers } = lastRequest(mock);
    expect(url).toBe(`${SUPABASE_URL}/functions/v1/user-create-order`);
    expect(init.method).toBe("POST");
    expect(init.body).toBe(JSON.stringify({ event_id: "e1" }));
    expect(headers["Content-Type"]).toBe("application/json");
    expect(headers["Authorization"]).toBe(`Bearer ${USER_TOKEN}`);
    expect(headers["apikey"]).toBe(ANON_KEY);
  });

  it("세션이 없으면 anon key 를 Bearer 로 폴백한다 (public caller EF 경로)", async () => {
    const mock = stubFetch(jsonResponse({ ok: true }));

    await callEdgeFunction(sessionSource(null), "user-event-feed", {});

    expect(lastRequest(mock).headers["Authorization"]).toBe(
      `Bearer ${ANON_KEY}`,
    );
  });

  it("options.accessToken 이 세션 토큰보다 우선한다", async () => {
    const mock = stubFetch(jsonResponse({ ok: true }));

    await callEdgeFunction(sessionSource(), "health", {}, {
      accessToken: "override-token",
    });

    expect(lastRequest(mock).headers["Authorization"]).toBe(
      "Bearer override-token",
    );
  });

  it("idempotencyKey 옵션이 있으면 Idempotency-Key 헤더로 그대로 싣는다", async () => {
    const mock = stubFetch(jsonResponse({ ok: true }));

    await callEdgeFunction(sessionSource(), "apply-event", {}, {
      idempotencyKey: "fixed-key-123",
    });

    expect(lastRequest(mock).headers["Idempotency-Key"]).toBe("fixed-key-123");
  });

  it("idempotencyKey 옵션이 없으면 Idempotency-Key 헤더를 보내지 않는다", async () => {
    const mock = stubFetch(jsonResponse({ ok: true }));

    await callEdgeFunction(sessionSource(), "user-cancel-order", {});

    expect(lastRequest(mock).headers).not.toHaveProperty("Idempotency-Key");
  });
});

describe("callEdgeFunction — 응답 검증 (zod)", () => {
  const schema = z.object({ success: z.literal(true), value: z.number() });

  it("2xx + 스키마 통과 → 파싱된 데이터를 반환한다", async () => {
    stubFetch(jsonResponse({ success: true, value: 42 }));

    const result = await callEdgeFunction(
      sessionSource(),
      "payment-verify",
      {},
      { schema },
    );

    expect(result).toEqual({ success: true, value: 42 });
  });

  it('2xx + 스키마 불일치 → MinglitError kind="contract" (zod issues 를 details 로)', async () => {
    stubFetch(jsonResponse({ success: true, value: "not-a-number" }));

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "payment-verify", {}, { schema }),
    );

    expect(error.kind).toBe("contract");
    expect(error.fn).toBe("payment-verify");
    expect(error.status).toBe(200);
    expect(Array.isArray(error.details)).toBe(true);
  });

  it("스키마 없이 호출하면 body 를 그대로 반환한다", async () => {
    stubFetch(jsonResponse({ anything: "goes" }));

    const result = await callEdgeFunction(sessionSource(), "health", {});

    expect(result).toEqual({ anything: "goes" });
  });
});

describe("callEdgeFunction — 에러 envelope 정규화 (MinglitError)", () => {
  it.each([
    [401, "auth"],
    [403, "auth"],
    [404, "not_found"],
    [409, "conflict"],
    [400, "validation"],
    [422, "validation"],
    [500, "server"],
    [503, "server"],
  ] as const)("HTTP %i → kind=%s", async (status, kind) => {
    stubFetch(jsonResponse({ error: "boom" }, status));

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "apply-event", {}),
    );

    expect(error.kind).toBe(kind);
    expect(error.status).toBe(status);
  });

  it("envelope { error, details } 를 message/details 로 파싱한다", async () => {
    stubFetch(
      jsonResponse(
        {
          error: "Eligibility requirements not met",
          details: { missing_verification_ids: ["v1", "v2"] },
        },
        403,
      ),
    );

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "apply-event", {}),
    );

    expect(error.message).toBe("Eligibility requirements not met");
    expect(error.details).toEqual({ missing_verification_ids: ["v1", "v2"] });
    expect(error.fn).toBe("apply-event");
  });

  it("details.code 가 있으면 머신 코드로 노출한다 (user-create-order 류)", async () => {
    stubFetch(
      jsonResponse(
        { error: "이미 신청한 이벤트입니다.", details: { code: "already_applied" } },
        400,
      ),
    );

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "user-create-order", {}),
    );

    expect(error.kind).toBe("validation");
    expect(error.code).toBe("already_applied");
  });

  it("429 → kind=rate_limit + details.retry_after_seconds 를 retryAfterSeconds 로", async () => {
    // _shared/edge_function.ts 의 rate limit 응답:
    // errorResponse(message, 429, { retry_after_seconds })
    stubFetch(
      jsonResponse(
        { error: "Rate limit exceeded", details: { retry_after_seconds: 12 } },
        429,
      ),
    );

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "apply-event", {}),
    );

    expect(error.kind).toBe("rate_limit");
    expect(error.retryAfterSeconds).toBe(12);
  });

  it("JSON 이 아닌 에러 body 면 status 기반 폴백 메시지를 쓴다", async () => {
    stubFetch(new Response("<html>gateway error</html>", { status: 502 }));

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "payment-cancel", {}),
    );

    expect(error.kind).toBe("server");
    expect(error.message).toBe("Edge function payment-cancel failed (502)");
  });

  it('fetch 자체가 실패하면 kind="network" + cause 보존', async () => {
    const cause = new TypeError("Failed to fetch");
    const mock = vi.fn<typeof fetch>().mockRejectedValueOnce(cause);
    vi.stubGlobal("fetch", mock);

    const error = await expectMinglitError(
      callEdgeFunction(sessionSource(), "identity-verify", {}),
    );

    expect(error.kind).toBe("network");
    expect(error.status).toBe(0);
    expect(error.cause).toBe(cause);
  });
});

describe("applyEvent wrapper — Idempotency-Key 자동 생성", () => {
  const UUID_RE =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  it("키 미지정 시 UUID 를 생성해 첨부한다 (manifest: idempotency required)", async () => {
    const mock = stubFetch(
      jsonResponse({ type: "free", application_id: "app-1" }),
    );

    await applyEvent(sessionSource(), { event_id: "e1", ticket_id: "t1" });

    const key = lastRequest(mock).headers["Idempotency-Key"];
    expect(key).toMatch(UUID_RE);
  });

  it("명시한 idempotencyKey 는 그대로 통과한다", async () => {
    const mock = stubFetch(
      jsonResponse({ type: "free", application_id: "app-1" }),
    );

    await applyEvent(
      sessionSource(),
      { event_id: "e1", ticket_id: "t1" },
      { idempotencyKey: "client-retry-key" },
    );

    expect(lastRequest(mock).headers["Idempotency-Key"]).toBe(
      "client-retry-key",
    );
  });
});
