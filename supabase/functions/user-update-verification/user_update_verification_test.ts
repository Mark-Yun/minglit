import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  authenticatedJsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const TEST_OPTS = { sanitizeOps: false, sanitizeResources: false };

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

// --- Route helpers ---

const verificationExistsRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/verifications") && req.method === "GET",
  handler: () => jsonResponse({ id: "ver-1" }),
};

const verificationNotFoundRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/verifications") && req.method === "GET",
  handler: () => jsonResponse(null),
};

const dbUpsertRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/user_verifications") && req.method === "POST",
  handler: () => jsonResponse({}),
};

const dbUpsertErrorRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/user_verifications") && req.method === "POST",
  handler: () => jsonResponse({ message: "DB error" }, { status: 400 }),
};

// ===== 정상 저장 =====

Deno.test("신규 저장 → user_verifications UPSERT 확인", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    verificationExistsRoute,
    dbUpsertRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          verification_id: "ver-1",
          data: { university: "서울대" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const upsertCall = calls.find(
          (c) => c.url.includes("/rest/v1/user_verifications") && c.method === "POST",
        );
        assertEquals(!!upsertCall, true);
        const body = JSON.parse(upsertCall!.body!);
        assertEquals(body.user_id, "user-123");
        assertEquals(body.verification_id, "ver-1");
        assertEquals(body.data.university, "서울대");
      });
    });
  });
});

Deno.test("기존 업데이트 → data 갱신 확인", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    verificationExistsRoute,
    dbUpsertRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          verification_id: "ver-1",
          data: { university: "연세대", gpa: "4.0" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const upsertCall = calls.find(
          (c) => c.url.includes("/rest/v1/user_verifications") && c.method === "POST",
        );
        const body = JSON.parse(upsertCall!.body!);
        assertEquals(body.data.university, "연세대");
        assertEquals(body.data.gpa, "4.0");
      });
    });
  });
});

// ===== 인증 없이 → 401 =====

Deno.test("인증 없이 → 401", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: (req: Request) => req.url.includes("/auth/v1/user"),
      handler: () => jsonResponse({ error: "invalid token" }, { status: 401 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          verification_id: "ver-1",
          data: { university: "서울대" },
        });
        const response = await handler(request);

        assertEquals(response.status, 401);
      });
    });
  });
});

// ===== verification_id 누락 → 400 =====

Deno.test("verification_id 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          data: { university: "서울대" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: verification_id");
      });
    });
  });
});

// ===== data 누락 → 400 =====

Deno.test("data 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          verification_id: "ver-1",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: data");
      });
    });
  });
});

// ===== 존재하지 않는 verification → 404 =====

Deno.test("존재하지 않는 verification → 404", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    verificationNotFoundRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          verification_id: "non-existent",
          data: { university: "서울대" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "Verification not found or inactive");
      });
    });
  });
});

// ===== malformed JSON → 400 =====

Deno.test("malformed JSON → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{invalid", {
          headers: { Authorization: "Bearer test-token" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});
