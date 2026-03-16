import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  authenticatedJsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("payment-cancel - happy path cancels payment and updates DB", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
    },
    {
      matcher: "https://api.iamport.kr/payments/cancel",
      handler: () => jsonResponse({ code: 0, response: { status: "cancelled", amount: 15000 } }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
      handler: () => jsonResponse({}),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
          reason: "user requested",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.refund_status, "completed");
      });
    });
  });
});

Deno.test("payment-cancel - missing payment_id returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { reason: "missing" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing payment_id");
      });
    });
  });
});

Deno.test("payment-cancel - token failure returns 502", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 1, message: "bad key" }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { payment_id: "imp_123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Payment provider error");
      });
    });
  });
});

Deno.test("payment-cancel - malformed JSON returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{invalid-json", { headers: { Authorization: "Bearer test-token" } });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});

Deno.test("payment-cancel - partial refund passes amount and checksum to iamport", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
    },
    {
      matcher: "https://api.iamport.kr/payments/cancel",
      handler: () => jsonResponse({ code: 0, response: { status: "cancelled", amount: 5000 } }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
      handler: () => jsonResponse({}),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_123",
          reason: "partial refund",
          amount: 5000,
          checksum: 15000,
        });

        const response = await handler(request);
        assertEquals(response.status, 200);

        const cancelCall = calls.find((c) => c.url.includes("/payments/cancel"));
        const cancelBody = JSON.parse(cancelCall!.body!);
        assertEquals(cancelBody.amount, 5000);
        assertEquals(cancelBody.checksum, 15000);

        const dbCall = calls.find((c) => c.url.includes("/rest/v1/event_applications") && c.method === "PATCH");
        const dbBody = JSON.parse(dbCall!.body!);
        assertEquals(dbBody.refund_status, "completed");
        assertEquals(dbBody.refund_amount, 5000);
      });
    });
  });
});

Deno.test("payment-cancel - DB error is non-fatal, still returns 200", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
    },
    {
      matcher: "https://api.iamport.kr/payments/cancel",
      handler: () => jsonResponse({ code: 0, response: { status: "cancelled" } }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
      handler: () => jsonResponse({ error: { message: "DB error" } }, { status: 500 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { payment_id: "imp_123" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
      });
    });
  });
});
