// Fix #1413: dev-seed EF는 images-only 모드만 지원.
// 유저/파트너 시딩은 seed.dev.sql로 이전됨.
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
  name: "dev-seed - images-only mode returns 200 with image_urls (images already in storage)",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
      {
        // All 3 seed images already exist — skip upload, return public URLs
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
        // getPublicUrl calls (3 images)
        matcher: (req) => req.url.includes("/storage/v1/object/public/"),
        handler: (req) => jsonResponse({ publicUrl: req.url }),
      },
    ]);

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          new Request("http://localhost?mode=images-only"),
        );
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.mode, "images-only");
        assertEquals(Array.isArray(body.image_urls), true);
        assertEquals(body.image_urls.length, 3);
        // No RPC fields — user/partner seeding is now in seed.dev.sql
        assertEquals(body.created_users, undefined);
        assertEquals(body.created_partners, undefined);
      });
    });
  },
});

Deno.test({
  name: "dev-seed - default mode is images-only (no ?mode param)",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
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
    ]);

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      await withMockedFetch(fetchMock, async () => {
        // No ?mode param — should default to images-only
        const response = await handler(new Request("http://localhost"));
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.mode, "images-only");
      });
    });
  },
});

Deno.test({
  name: "dev-seed - mode=static returns 400 (data seeding moved to seed.dev.sql)",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      const response = await handler(
        new Request("http://localhost?mode=static"),
      );
      assertEquals(response.status, 400);
      const body = await readJson(response);
      assertEquals(typeof body.error, "string");
    });
  },
});

Deno.test({
  name: "dev-seed - mode=full returns 400 (data seeding moved to seed.dev.sql)",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    await withEnv({
      ENVIRONMENT: "development",
      SUPABASE_URL: "http://localhost:54321",
      SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
    }, async () => {
      const response = await handler(
        new Request("http://localhost?mode=full"),
      );
      assertEquals(response.status, 400);
      const body = await readJson(response);
      assertEquals(typeof body.error, "string");
    });
  },
});
