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
  name: "dev-session-switch - blocks in production (DENO_DEPLOYMENT_ID set)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    
    await withEnv({ DENO_DEPLOYMENT_ID: "prod123" }, async () => {
      const response = await handler(new Request("http://localhost"));
      assertEquals(response.status, 403);
      const body = await readJson(response);
      assertEquals(body.error, "Dev-only function. Blocked in production.");
    });
  },
});

Deno.test({
  name: "dev-session-switch - returns user profiles in local env",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    
    const mockUsers = [
      { id: "1", name: "Test User", username: "user_25_m_ok" },
      { id: "2", name: "Test User 2", username: "user_30_f_ok" },
    ];
    
    const { fetchMock } = createFetchMock([
      {
        matcher: /user_profiles/,
        handler: () => jsonResponse(mockUsers),
      },
    ]);
    
    await withEnv({
      DENO_DEPLOYMENT_ID: undefined,
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.users.length, 2);
        assertEquals(body.users[0].username, "user_25_m_ok");
      });
    });
  },
});

Deno.test({
  name: "dev-session-switch - handles Supabase error",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    
    const { fetchMock } = createFetchMock([
      {
        matcher: /user_profiles/,
        handler: () => jsonResponse({ message: "Database connection failed" }, { status: 500 }),
      },
    ]);
    
    await withEnv({
      DENO_DEPLOYMENT_ID: undefined,
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        assertEquals(response.status, 500);
        const body = await readJson(response);
        assertEquals(typeof body.error, "string");
      });
    });
  },
});
