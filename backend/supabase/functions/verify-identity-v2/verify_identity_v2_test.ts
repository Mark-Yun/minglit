import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { mockPortoneVerification, mockUser } from "../_test_utils/fixtures.ts";

Deno.test("verify-identity-v2 - happy path updates profile", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.portone.io/identity-verifications/verify_123",
      handler: () => jsonResponse(mockPortoneVerification),
    },
    {
      matcher: (req) => req.url.includes("/auth/v1/user"),
      handler: () => jsonResponse(mockUser),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_profiles") && req.method === "PATCH",
      handler: () => jsonResponse({}),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { identity_verification_id: "verify_123" },
            { headers: { Authorization: "Bearer test-token" } },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.user, mockUser.id);
        });
      });
    },
  );
});

Deno.test("verify-identity-v2 - missing id returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest("http://localhost", {});
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Missing identity_verification_id");
        });
      });
    },
  );
});

Deno.test("verify-identity-v2 - external API error returns status", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.portone.io/identity-verifications/verify_123",
      handler: () => jsonResponse({ message: "failure" }, { status: 500 }),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest("http://localhost", {
            identity_verification_id: "verify_123",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(payload.error, "Failed to fetch verification info");
        });
      });
    },
  );
});

Deno.test("verify-identity-v2 - unauthorized returns 401", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.portone.io/identity-verifications/verify_123",
      handler: () => jsonResponse(mockPortoneVerification),
    },
    {
      matcher: (req) => req.url.includes("/auth/v1/user"),
      handler: () => jsonResponse({}),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest("http://localhost", {
            identity_verification_id: "verify_123",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 401);
          assertEquals(payload.error, "Unauthorized");
        });
      });
    },
  );
});

Deno.test("verify-identity-v2 - malformed JSON returns 500", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = textRequest("http://localhost", "{bad-json");
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(typeof payload.error, "string");
        });
      });
    },
  );
});
