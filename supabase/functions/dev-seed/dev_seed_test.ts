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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
      {
        // dev_seed_bulk_users RPC: returns created/updated/total counts
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_users") &&
          req.method === "POST",
        handler: () =>
          jsonResponse({ created: 560, updated: 0, total: 560, elapsed_ms: 100 }),
      },
      {
        // dev_seed_bulk_partners RPC: returns partners_processed count
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_partners") &&
          req.method === "POST",
        handler: () =>
          jsonResponse({
            partners_processed: 5,
            locations: 5,
            verifications: 5,
            elapsed_ms: 100,
          }),
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
        // pgmq_purge and other RPCs
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/") && req.method === "POST",
        handler: () => jsonResponse(null),
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

        // created_users reflects `created` field from dev_seed_bulk_users RPC
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
  name: "dev-seed - dev_seed_bulk_users RPC is called once (not per-user)",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    let bulkUsersRpcCallCount = 0;

    const { fetchMock } = createFetchMock([
      {
        // dev_seed_bulk_users RPC — must be called exactly once for all 560 users
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_users") &&
          req.method === "POST",
        handler: () => {
          bulkUsersRpcCallCount++;
          return jsonResponse({
            created: 560,
            updated: 0,
            total: 560,
            elapsed_ms: 100,
          });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_partners") &&
          req.method === "POST",
        handler: () =>
          jsonResponse({
            partners_processed: 5,
            locations: 5,
            verifications: 5,
            elapsed_ms: 100,
          }),
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
          req.url.includes("/rest/v1/rpc/") && req.method === "POST",
        handler: () => jsonResponse(null),
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
        // Bulk RPC called exactly once (not once per user)
        assertEquals(bulkUsersRpcCallCount, 1);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - dev_seed_bulk_users RPC error propagates as 500",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
      {
        // Simulate dev_seed_bulk_users RPC returning a DB error
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_users") &&
          req.method === "POST",
        handler: () =>
          jsonResponse(
            { message: "internal server error", code: "PGRST301" },
            { status: 500 },
          ),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/") && req.method === "POST",
        handler: () => jsonResponse(null),
      },
    ]);

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(new Request("http://localhost"));
        // RPC failure propagates as 500
        assertEquals(response.status, 500);
        const body = await readJson(response);
        assertEquals(typeof body.error, "string");
      });
    });
  },
});

Deno.test({
  name: "dev-seed - mode=static is idempotent (re-run does not error)",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    // Simulate second run: dev_seed_bulk_users RPC handles upsert idempotently
    // (returns updated > 0 instead of created > 0 — but no error thrown)
    let bulkUsersRpcCallCount = 0;

    const { fetchMock } = createFetchMock([
      {
        // Second run: all users already exist → all updated, none created
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_users") &&
          req.method === "POST",
        handler: () => {
          bulkUsersRpcCallCount++;
          return jsonResponse({
            created: 0,
            updated: 560,
            total: 560,
            elapsed_ms: 120,
          });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_partners") &&
          req.method === "POST",
        handler: () =>
          jsonResponse({
            partners_processed: 5,
            locations: 0,
            verifications: 0,
            elapsed_ms: 80,
          }),
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
          req.url.includes("/rest/v1/rpc/") && req.method === "POST",
        handler: () => jsonResponse(null),
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
        // Second run must succeed without errors
        assertEquals(response.status, 200);
        // Bulk RPC called exactly once (not once per user)
        assertEquals(bulkUsersRpcCallCount, 1);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - mode=static with extra query params does not error (#1334)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    // Bulk RPC refactor (#1390): offset/limit params are ignored.
    // All 560 users are seeded via a single dev_seed_bulk_users RPC call.
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_users") &&
          req.method === "POST",
        handler: () =>
          jsonResponse({ created: 560, updated: 0, total: 560, elapsed_ms: 100 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/rpc/dev_seed_bulk_partners") &&
          req.method === "POST",
        handler: () =>
          jsonResponse({
            partners_processed: 5,
            locations: 5,
            verifications: 5,
            elapsed_ms: 100,
          }),
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
          req.url.includes("/rest/v1/rpc/") && req.method === "POST",
        handler: () => jsonResponse(null),
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
        // Extra query params are accepted but ignored; all 560 users seeded via RPC
        const response = await handler(
          new Request("http://localhost?mode=static&offset=0&limit=100"),
        );
        assertEquals(response.status, 200);
        const body = await readJson(response);
        // All 560 users always seeded (offset/limit no longer batches HTTP calls)
        assertEquals(body.created_users, 560);
        assertEquals(body.created_partners, 5);
      });
    });
  },
});
