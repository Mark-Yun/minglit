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
import { mockOrder, mockPaidPayment, mockReadyPayment } from "../_test_utils/fixtures.ts";

const ENV = {
  PORTONE_IMP_KEY: "test-key",
  PORTONE_IMP_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("verify-payment-v1 - happy path approves order", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_123",
        handler: () => jsonResponse({ code: 0, response: mockPaidPayment }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(mockOrder),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {
          imp_uid: "imp_123",
          merchant_uid: "order-123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.imp_uid, "imp_123");
      });
    });
  });
});

Deno.test("verify-payment-v1 - missing params returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", { merchant_uid: "order-123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required parameters");
      });
    });
  });
});

Deno.test("verify-payment-v1 - payment not completed returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_ready",
        handler: () => jsonResponse({ code: 0, response: mockReadyPayment }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(mockOrder),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {
          imp_uid: "imp_ready",
          merchant_uid: "order-123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Payment not completed");
      });
    });
  });
});

Deno.test("verify-payment-v1 - amount mismatch returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_mismatch",
        handler: () => jsonResponse({ code: 0, response: { ...mockPaidPayment, amount: 999 } }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(mockOrder),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {
          imp_uid: "imp_mismatch",
          merchant_uid: "order-123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Amount mismatch");
      });
    });
  });
});

Deno.test("verify-payment-v1 - iamport failure returns 500", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => new Response("Iamport down", { status: 500 }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(mockOrder),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {
          imp_uid: "imp_fail",
          merchant_uid: "order-123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 500);
        assertEquals(typeof payload.error, "string");
      });
    });
  });
});

Deno.test("verify-payment-v1 - malformed JSON returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{oops");
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});
