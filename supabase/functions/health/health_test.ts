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
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
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
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 500 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
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
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
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
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: "/rest/v1/", handler: () => new Response(null, { status: 200 }) },
      { matcher: "/auth/v1/health", handler: () => jsonResponse({ status: "ok" }) },
      { matcher: "/storage/v1/bucket", handler: () => jsonResponse([]) },
    ]);

    await withEnv({
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
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request("http://localhost", { method: "POST" }));
    assertEquals(response.status, 405);
  },
});
