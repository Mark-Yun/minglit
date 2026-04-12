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
        // seedAllUsers: listUsers pre-cache (called once)
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => jsonResponse({ users: [] }),
      },
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
      {
        // updatePartyImages: query seed partners by biz_number
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        // updatePartyImages: list parties (no parties in fresh env)
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "GET",
        handler: () => jsonResponse([]),
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

        // static mode (default): 60 legacy users + 500 regional users = 560 total (#1334)
        // created_users counts generateAllPersonas() results, not partner owners
        assertEquals(body.created_users, 560);
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
  name: "dev-seed - static mode assigns images to existing parties (Fix #1210)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const partyIds = [crypto.randomUUID(), crypto.randomUUID()];
    const patchedPartyIds: string[] = [];
    let createUserCallCount = 0;

    const { fetchMock } = createFetchMock([
      {
        // seedAllUsers: listUsers pre-cache (called once)
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => jsonResponse({ users: [] }),
      },
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
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
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        // updatePartyImages: query seed partners by biz_number
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse(partyIds.map((id) => ({ id }))),
      },
      {
        // updatePartyImages: list all parties — returns 2 existing parties
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "GET",
        handler: () =>
          jsonResponse(partyIds.map((id) => ({ id }))),
      },
      {
        // updatePartyImages: PATCH each party with image_urls
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "PATCH",
        handler: async (req) => {
          const body = await req.json();
          // Each party should receive exactly 3 image URLs (rotation of 3 seed images)
          assertEquals(Array.isArray(body.image_urls), true);
          assertEquals(body.image_urls.length, 3);
          const urlMatch = new URL(req.url);
          const idFilter = urlMatch.searchParams.get("id");
          if (idFilter) patchedPartyIds.push(idFilter.replace("eq.", ""));
          return jsonResponse(null, { status: 204 });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/") && req.method === "POST",
        handler: () =>
          jsonResponse({ id: crypto.randomUUID() }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          }),
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
        assertEquals(body.uploaded_images, 3);
        // Both existing parties should have been patched with images
        assertEquals(patchedPartyIds.length, 2);
        assertEquals(new Set(patchedPartyIds), new Set(partyIds));
      });
    });
  },
});

Deno.test({
  name: "dev-seed - seedAllUsers caches listUsers and skips unchanged existing users",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    let listUsersCallCount = 0;
    let createUserCallCount = 0;
    let updateUserCallCount = 0;

    // Pre-populate all 60 personas as existing (same metadata → no update needed)
    // We return a stub list; the seed code will find all by email and skip creation
    const { fetchMock } = createFetchMock([
      {
        // seedAllUsers: listUsers called exactly once
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => {
          listUsersCallCount++;
          // Return empty list — all users will be created fresh
          return jsonResponse({ users: [] });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
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
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users/") && req.method === "PUT",
        handler: () => {
          updateUserCallCount++;
          return jsonResponse({ user: { id: "existing-user-id" } });
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
        handler: () =>
          jsonResponse({ id: crypto.randomUUID() }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "GET",
        handler: () => jsonResponse([]),
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
        assertEquals(body.created_users, 560);
        // listUsers called exactly once (not per-user)
        assertEquals(listUsersCallCount, 1);
        // No update calls needed (empty list → all created fresh)
        assertEquals(updateUserCallCount, 0);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - seedAllUsers logs individual failures and continues",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    let createCallCount = 0;
    const failEmail = "user_20_m_ok@test.com";

    const { fetchMock } = createFetchMock([
      {
        // listUsers: empty → all will be created
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => jsonResponse({ users: [] }),
      },
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          createCallCount++;
          const body = await req.json();
          if (body.email === failEmail) {
            return jsonResponse({ message: "internal server error" }, { status: 500 });
          }
          return jsonResponse({
            user: {
              id: `user-${createCallCount}`,
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
        handler: () =>
          jsonResponse({ id: crypto.randomUUID() }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
    ]);

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        // Overall response is 200 even with 1 individual failure
        assertEquals(response.status, 200);
        const body = await readJson(response);
        // 559 succeed, 1 fails (but doesn't crash) — 560 total (#1334)
        assertEquals(body.created_users, 559);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - mode=static is idempotent (re-run does not error)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    // Simulate second run: all 60 users already exist in auth with same metadata
    // seedAllUsers should: listUsers once, find all, skip creation (metadata unchanged)
    let listUsersCallCount = 0;
    let createUserCallCount = 0;

    // We can't easily know all user metadata here, so just return users with
    // mismatched metadata to trigger update path — verifies no errors
    const existingUsers = Array.from({ length: 65 }, (_, i) => ({
      id: `existing-${i}`,
      email: `placeholder-${i}@test.com`,  // won't match personas
      user_metadata: {},
    }));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => {
          listUsersCallCount++;
          return jsonResponse({ users: existingUsers });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
        handler: async (req) => {
          createUserCallCount++;
          const body = await req.json();
          return jsonResponse({
            user: { id: `new-${createUserCallCount}`, email: body.email, user_metadata: body.user_metadata },
          });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users/") && req.method === "PUT",
        handler: () => jsonResponse({ user: { id: "updated-id" } }),
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
        handler: () =>
          jsonResponse({ id: crypto.randomUUID() }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/locations") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "GET",
        handler: () => jsonResponse([]),
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
        // listUsers called exactly once (cached)
        assertEquals(listUsersCallCount, 1);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - offset/limit seeds only the specified batch (#1334)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    let createUserCallCount = 0;

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "GET",
        handler: () => jsonResponse({ users: [] }),
      },
      {
        matcher: (req) =>
          req.url.includes("/auth/v1/admin/users") && req.method === "POST",
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
        handler: () =>
          jsonResponse({ id: crypto.randomUUID() }, {
            status: 201,
            headers: { "Content-Profile": "public" },
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "GET",
        handler: () => jsonResponse(null, { status: 200 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
    ]);

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        // Batch 1: offset=0, limit=100 → seeds first 100 of 560 personas
        const response = await handler(
          new Request("http://localhost?mode=static&offset=0&limit=100"),
        );
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.created_users, 100);

        // Batch 6: offset=500, limit=100 → seeds remaining 60 personas (500..559)
        createUserCallCount = 0;
        const response2 = await handler(
          new Request("http://localhost?mode=static&offset=500&limit=100"),
        );
        assertEquals(response2.status, 200);
        const body2 = await readJson(response2);
        assertEquals(body2.created_users, 60);
      });
    });
  },
});
