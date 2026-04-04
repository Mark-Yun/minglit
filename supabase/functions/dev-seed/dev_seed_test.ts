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
  name: "dev-seed - blocks in production (ENVIRONMENT=production)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    await withEnv({ ENVIRONMENT: "production" }, async () => {
      const response = await handler(new Request("http://localhost"));
      assertEquals(response.status, 403);
      const body = await readJson(response);
      assertEquals(body.error, "Dev-only function. Blocked in production.");
    });
  },
});

Deno.test({
  name: "dev-seed - seeds users and partners in static mode (default)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    let createUserCallCount = 0;
    let insertCounter = 0;

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          createUserCallCount++;
          const body = await req.json();
          assertEquals(body.app_metadata, { has_password: true });
          return jsonResponse({
            user: {
              id: `user-${createUserCallCount}`,
              email: body.email,
              user_metadata: body.user_metadata,
            },
          });
        },
      },
      {
        matcher: (req) => req.url.includes("/storage/v1/object/list-v2/"),
        handler: () =>
          jsonResponse({
            objects: [
              { name: "seed-images/party_cafe_warm.jpg" },
              { name: "seed-images/party_lounge_bright.jpg" },
              { name: "seed-images/party_premium_lounge.jpg" },
            ],
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/") && req.method === "POST",
        handler: async (req) => {
          insertCounter++;
          const id = crypto.randomUUID();
          const url = new URL(req.url);
          url.pathname.split("/rest/v1/")[1]?.split("?")[0];

          const prefer = req.headers.get("Prefer") ?? "";
          if (prefer.includes("return=representation")) {
            return jsonResponse({ id }, {
              status: 201,
              headers: { "Content-Profile": "public" },
            });
          }
          return jsonResponse({ id }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => {
          return jsonResponse(null, { status: 200 });
        },
      },
    ]);

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        assertEquals(response.status, 200);
        const body = await readJson(response);

        // static mode (default): 60 users (age 20-34 × 4 variants) + 5 partner owners
        // created_users counts only generateAllPersonas() results (60), not partner owners
        assertEquals(body.created_users, 60);
        assertEquals(body.created_partners, 5);
        // static mode does not create parties/events — those require ?mode=full
        assertEquals(body.created_parties, undefined);
        assertEquals(body.created_events, undefined);
        assertEquals(body.uploaded_images, 3);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - skip existing user on duplicate (no delete-and-retry)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    let createUserAttempts = 0;
    let deleteUserCalled = false;
    const duplicateEmail = "user_20_m_ok@test.com";
    const existingUserId = crypto.randomUUID();

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          createUserAttempts++;
          const body = await req.json();
          assertEquals(body.app_metadata, { has_password: true });

          if (body.email === duplicateEmail && createUserAttempts === 1) {
            return jsonResponse(
              { message: "User already registered" },
              { status: 422 },
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
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
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
        matcher: (req) =>
          req.url.includes(`/auth/v1/admin/users/${existingUserId}`) &&
          req.method === "PUT",
        handler: async (req) => {
          const body = await req.json();
          assertEquals(body.app_metadata, { has_password: true });
          return jsonResponse({ user: { id: existingUserId } });
        },
      },
      {
        matcher: (req) => req.url.includes("/storage/v1/object/list-v2/"),
        handler: () =>
          jsonResponse({
            objects: [
              { name: "seed-images/party_cafe_warm.jpg" },
              { name: "seed-images/party_lounge_bright.jpg" },
              { name: "seed-images/party_premium_lounge.jpg" },
            ],
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/") && req.method === "POST",
        handler: () => {
          return jsonResponse({ id: crypto.randomUUID() }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => {
          return jsonResponse(null, { status: 200 });
        },
      },
    ]);

    await withEnv({
      ENVIRONMENT: "local",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        assertEquals(response.status, 200);
        const body = await readJson(response);
        // duplicate user is found via listUsers and returned — still counted, not skipped
        assertEquals(body.created_users, 60);
        // duplicate handling: skip existing user without deleting
        assertEquals(deleteUserCalled, false);
        assertEquals(createUserAttempts >= 21, true);
      });
    });
  },
});

Deno.test({
  name:
    "dev-seed - fails when repairing duplicate user password metadata fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const duplicateEmail = "user_20_m_ok@test.com";
    const existingUserId = crypto.randomUUID();

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          const body = await req.json();
          assertEquals(body.app_metadata, { has_password: true });

          if (body.email === duplicateEmail) {
            return jsonResponse(
              { message: "User already registered" },
              { status: 422 },
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
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () =>
          jsonResponse({
            users: [
              {
                id: existingUserId,
                email: duplicateEmail,
              },
            ],
          }),
      },
      {
        matcher: (req) =>
          req.url.includes(`/auth/v1/admin/users/${existingUserId}`) &&
          req.method === "PUT",
        handler: async (req) => {
          const body = await req.json();
          assertEquals(body.app_metadata, { has_password: true });
          return jsonResponse(
            { message: "update failed" },
            { status: 500 },
          );
        },
      },
    ]);

    await withEnv({
      ENVIRONMENT: "local",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        assertEquals(response.status, 500);
        const body = await readJson(response);
        assertEquals(
          body.error,
          `Failed to repair existing user ${duplicateEmail} (${existingUserId}): update failed`,
        );
      });
    });
  },
});
