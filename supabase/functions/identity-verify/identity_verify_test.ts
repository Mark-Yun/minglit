import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  authenticatedJsonRequest,
  jsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { authRoute, mockPortoneVerification, mockUser } from "../_test_utils/fixtures.ts";

Deno.test("identity-verify - happy path updates profile", async () => {
  await withEnv(
    {
      PORTONE_V2_API_KEY: "test-key",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
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
          matcher: (req) => req.url.includes("/rest/v1/rpc/update_user_identity") && req.method === "POST",
          handler: () => jsonResponse(null),
        },
      ]);

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

Deno.test("identity-verify - missing id returns 400", async () => {
  await withEnv(
    {
      PORTONE_V2_API_KEY: "test-key",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([authRoute]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = authenticatedJsonRequest("http://localhost", {});
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Missing identity_verification_id");
        });
      });
    },
  );
});

Deno.test("identity-verify - external API error returns status", async () => {
  await withEnv(
    {
      PORTONE_V2_API_KEY: "test-key",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        authRoute,
        {
          matcher: "https://api.portone.io/identity-verifications/verify_123",
          handler: () => jsonResponse({ message: "failure" }, { status: 500 }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = authenticatedJsonRequest("http://localhost", {
            identity_verification_id: "verify_123",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 502);
          assertEquals(payload.error, "Failed to fetch verification info");
        });
      });
    },
  );
});

Deno.test("identity-verify - unauthorized returns 401", async () => {
  await withEnv(
    {
      PORTONE_V2_API_KEY: "test-key",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        {
          matcher: "https://api.portone.io/identity-verifications/verify_123",
          handler: () => jsonResponse(mockPortoneVerification),
        },
        {
          matcher: (req) => req.url.includes("/auth/v1/user"),
          handler: () => jsonResponse({}, { status: 401 }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = authenticatedJsonRequest("http://localhost", {
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

Deno.test("identity-verify - RPC failure returns 500", async () => {
  await withEnv(
    {
      PORTONE_V2_API_KEY: "test-key",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
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
          matcher: (req) => req.url.includes("/rest/v1/rpc/update_user_identity"),
          handler: () => jsonResponse({ message: "pii_encryption_key not found" }, { status: 400 }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { identity_verification_id: "verify_123" },
            { headers: { Authorization: "Bearer test-token" } },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(payload.error, "Failed to update user profile");
        });
      });
    },
  );
});

Deno.test("identity-verify - malformed JSON returns 500", async () => {
  await withEnv(
    {
      PORTONE_V2_API_KEY: "test-key",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([authRoute]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = textRequest("http://localhost", "{bad-json", { headers: { Authorization: "Bearer test-token" } });
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(typeof payload.error, "string");
        });
      });
    },
  );
});
