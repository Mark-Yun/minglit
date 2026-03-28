import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  textRequest,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("payment-webhook - happy path updates status", async () => {
  await withEnv(ENV, async () => {
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
  });
});

Deno.test("payment-webhook - unauthorized IP returns 403", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

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
  });
});

Deno.test("payment-webhook - missing params returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

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
  });
});

Deno.test("payment-webhook - merchant UID mismatch returns 400", async () => {
  await withEnv(ENV, async () => {
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
  });
});

Deno.test("payment-webhook - iamport error returns 500", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => new Response("error", { status: 500 }),
      },
    ]);

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
  });
});

Deno.test("payment-webhook - malformed JSON returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{bad-json", {
          headers: { "x-forwarded-for": "127.0.0.1" },
        });
        const response = await handler(request);
        assertEquals(response.status, 400);
        assertEquals(typeof (await response.text()), "string");
      });
    });
  });
});

Deno.test("payment-webhook - cancelled status sets refund_status completed", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock, calls } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_cancel",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-456", status: "cancelled" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_cancel", merchant_uid: "order-456", status: "cancelled" },
          { headers: { "x-forwarded-for": "127.0.0.1" } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.status, "cancelled");
        assertEquals(dbBody.refund_status, "completed");
      });
    });
  });
});

Deno.test("payment-webhook - paid status does not set refund_status", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock, calls } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_paid",
        handler: () => jsonResponse({ code: 0, response: { merchant_uid: "order-789", status: "paid" } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest(
          "http://localhost",
          { imp_uid: "imp_paid", merchant_uid: "order-789", status: "paid" },
          { headers: { "x-forwarded-for": "127.0.0.1" } },
        );
        const response = await handler(request);
        assertEquals(response.status, 200);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.status, "approved");
        assertEquals(dbBody.refund_status, undefined);
      });
    });
  });
});
