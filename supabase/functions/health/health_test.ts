import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

Deno.test({
  name: "health - returns 200 with healthy status when all checks pass",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost", { method: "GET" }));
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.status, "healthy");
        assertEquals(body.checks.database.status, "up");
        assertEquals(body.checks.auth.status, "up");
        assertEquals(body.checks.storage.status, "up");
      });
    });
  },
});

Deno.test({
  name: "health - returns 503 when database is down",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 500 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost", { method: "GET" }));
        assertEquals(response.status, 503);

        const body = await readJson(response);
        assertEquals(body.details.status, "unhealthy");
        assertEquals(body.details.checks.database.status, "down");
        assertEquals(body.details.checks.auth.status, "up");
      });
    });
  },
});

Deno.test({
  name: "health - response contains required keys",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost", { method: "GET" }));
        const body = await readJson(response);

        assertEquals(typeof body.status, "string");
        assertEquals(typeof body.timestamp, "string");
        assertEquals(typeof body.checks, "object");
        assertEquals(typeof body.checks.database.latency_ms, "number");
        assertEquals(typeof body.checks.auth.latency_ms, "number");
        assertEquals(typeof body.checks.storage.latency_ms, "number");
      });
    });
  },
});

Deno.test({
  name: "health - returns Content-Type application/json",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost", { method: "GET" }));
        assertEquals(response.headers.get("Content-Type"), "application/json");
      });
    });
  },
});

Deno.test({
  name: "health - rejects non-GET with 405",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      const response = await handler(new Request("http://localhost", { method: "POST" }));
      assertEquals(response.status, 405);
    });
  },
});

// Fix #1944: ?env=true must require service_role — key names are infrastructure-sensitive
Deno.test({
  name: "health - ?env=true without auth returns 401",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          new Request("http://localhost?env=true", { method: "GET" }),
        );
        assertEquals(response.status, 401);
      });
    });
  },
});

Deno.test({
  name: "health - ?env=true with wrong bearer returns 401",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          new Request("http://localhost?env=true", {
            method: "GET",
            headers: { Authorization: "Bearer wrong-key" },
          }),
        );
        assertEquals(response.status, 401);
      });
    });
  },
});

Deno.test({
  name: "health - ?env=true with correct service role returns env_check",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "health",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_ANON_KEY: "test-anon-key",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          new Request("http://localhost?env=true", {
            method: "GET",
            headers: { Authorization: "Bearer test-service-key" },
          }),
        );
        const body = await readJson(response);
        assertEquals(typeof body.env_check, "object");
        assertEquals(typeof body.env_check.status, "string");
      });
    });
  },
});
