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

Deno.test("portone-webhook-v1 - happy path updates status", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
    },
    {
      matcher: "https://api.iamport.kr/payments/imp_abc",
      handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-123", status: "paid" } }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
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
            { imp_uid: "imp_abc", merchant_uid: "order-123", status: "paid" },
            { headers: { "x-forwarded-for": "127.0.0.1" } },
          );
          const response = await handler(request);

          assertEquals(response.status, 200);
          assertEquals(await response.text(), "OK");
        });
      });
    },
  );
});

Deno.test("portone-webhook-v1 - unauthorized IP returns 403", async () => {
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
          const request = jsonRequest(
            "http://localhost",
            { imp_uid: "imp_abc", merchant_uid: "order-123", status: "paid" },
            { headers: { "x-forwarded-for": "10.0.0.1" } },
          );
          const response = await handler(request);
          assertEquals(response.status, 403);
          assertEquals(await response.text(), "Unauthorized IP");
        });
      });
    },
  );
});

Deno.test("portone-webhook-v1 - missing params returns 400", async () => {
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
          const request = jsonRequest(
            "http://localhost",
            { status: "paid" },
            { headers: { "x-forwarded-for": "127.0.0.1" } },
          );
          const response = await handler(request);
          assertEquals(response.status, 400);
          assertEquals(await response.text(), "Missing parameters");
        });
      });
    },
  );
});

Deno.test("portone-webhook-v1 - merchant UID mismatch returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
    },
    {
      matcher: "https://api.iamport.kr/payments/imp_abc",
      handler: () => jsonResponse({ code: 0, response: { merchant_uid: "other", status: "paid" } }),
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
            { imp_uid: "imp_abc", merchant_uid: "order-123" },
            { headers: { "x-forwarded-for": "127.0.0.1" } },
          );
          const response = await handler(request);
          assertEquals(response.status, 400);
          assertEquals(await response.text(), "Merchant UID mismatch");
        });
      });
    },
  );
});

Deno.test("portone-webhook-v1 - iamport error returns 500", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => new Response("error", { status: 500 }),
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
            { imp_uid: "imp_abc", merchant_uid: "order-123" },
            { headers: { "x-forwarded-for": "127.0.0.1" } },
          );
          const response = await handler(request);
          assertEquals(response.status, 500);
          assertEquals(typeof (await response.text()), "string");
        });
      });
    },
  );
});

Deno.test("portone-webhook-v1 - malformed JSON returns 500", async () => {
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
          const request = textRequest("http://localhost", "{bad-json", {
            headers: { "x-forwarded-for": "127.0.0.1" },
          });
          const response = await handler(request);
          assertEquals(response.status, 500);
          assertEquals(typeof (await response.text()), "string");
        });
      });
    },
  );
});
