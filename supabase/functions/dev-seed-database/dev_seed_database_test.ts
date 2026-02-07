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
  name: "dev-seed-database - blocks in production (DENO_DEPLOYMENT_ID set)",
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
  name: "dev-seed-database - creates 20 users successfully",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    
    let createUserCallCount = 0;
    
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          createUserCallCount++;
          const body = await req.json();
          return jsonResponse({
            user: {
              id: `user-${createUserCallCount}`,
              email: body.email,
              user_metadata: body.user_metadata,
            },
          });
        },
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
        assertEquals(body.created_users, 20);
        assertEquals(body.total_requested, 20);
        assertEquals(createUserCallCount, 20);
      });
    });
  },
});

Deno.test({
  name: "dev-seed-database - delete-and-retry on duplicate user",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    
    let createUserAttempts = 0;
    let deleteUserCalled = false;
    const duplicateEmail = "user_20_m_ok@test.com";
    const existingUserId = crypto.randomUUID();
    
    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          createUserAttempts++;
          const body = await req.json();
          
          if (body.email === duplicateEmail && createUserAttempts === 1) {
            return jsonResponse(
              { message: "User already registered" },
              { status: 422 }
            );
          }
          
          return jsonResponse({
            user: {
              id: crypto.randomUUID(),
              email: body.email,
              user_metadata: body.user_metadata,
            },
          });
        },
      },
      {
        matcher: (req) => req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => {
          return jsonResponse({
            users: [
              {
                id: existingUserId,
                email: duplicateEmail,
              },
            ],
          });
        },
      },
      {
        matcher: (req) => req.url.includes(`/auth/v1/admin/users/${existingUserId}`) && req.method === "DELETE",
        handler: () => {
          deleteUserCalled = true;
          return jsonResponse({ user: { id: existingUserId } });
        },
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
        assertEquals(body.created_users, 20);
        assertEquals(deleteUserCalled, true);
        assertEquals(createUserAttempts >= 21, true);
      });
    });
  },
});
