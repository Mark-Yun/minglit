import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import {
  authRoute,
  mockOrder,
  mockPaidPayment,
  mockReadyPayment,
  mockUser,
} from "../_test_utils/fixtures.ts";

// Fix #1490: ownership check — user_id must match authenticated user
const mockOrderWithOwner = { ...mockOrder, user_id: mockUser.id };

const ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "payment-verify",
};

Deno.test("payment-verify - happy path approves order", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () =>
          jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_123",
        handler: () => jsonResponse({ code: 0, response: mockPaidPayment }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "GET",
        handler: () => jsonResponse(mockOrderWithOwner),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          imp_uid: "imp_123",
          merchant_uid: "order-123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.imp_uid, "imp_123");
        assertEquals(payload.application_id, "order-123");
      });
    });
  });
});

Deno.test("payment-verify - PortOne V2 happy path approves order by payment_id", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "GET",
        handler: () => jsonResponse({ ...mockOrderWithOwner, id: "order-123" }),
      },
      {
        matcher: "https://api.portone.io/payments/pay123",
        handler: () =>
          jsonResponse({
            id: "pay123",
            paymentId: "pay123",
            status: "PAID",
            amount: { total: mockOrder.payment_amount },
            paidAt: "2026-06-08T00:00:00Z",
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          provider: "portone_v2",
          payment_id: "pay123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "paid");
        assertEquals(payload.payment_id, "pay123");
        assertEquals(payload.application_id, "order-123");
        assertEquals(payload.purchase_url, "/my/purchases?purchase=order-123");
      });
    });
  });
});

Deno.test("payment-verify - missing params returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          merchant_uid: "order-123",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required parameters");
      });
    });
  });
});

Deno.test("payment-verify - payment not completed returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () =>
          jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_ready",
        handler: () => jsonResponse({ code: 0, response: mockReadyPayment }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "GET",
        handler: () => jsonResponse(mockOrderWithOwner),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
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

Deno.test("payment-verify - amount mismatch returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () =>
          jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_mismatch",
        handler: () =>
          jsonResponse({
            code: 0,
            response: { ...mockPaidPayment, amount: 999 },
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "GET",
        handler: () => jsonResponse(mockOrderWithOwner),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
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

Deno.test("payment-verify - iamport failure returns 500", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => new Response("Iamport down", { status: 500 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "GET",
        handler: () => jsonResponse(mockOrderWithOwner),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
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

// Fix #1490: 타인의 merchant_uid로 결제 승인 시도 → 403 반환 (IDOR 방어)
Deno.test("payment-verify - other user's order returns 403", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") &&
          req.method === "GET",
        handler: () =>
          jsonResponse({ ...mockOrderWithOwner, user_id: "other-user-999" }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          imp_uid: "imp_123",
          merchant_uid: "order-other",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 403);
        assertEquals(payload.error, "Forbidden");
      });
    });
  });
});

Deno.test("payment-verify - malformed JSON returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{oops", {
          headers: { Authorization: "Bearer test-token" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});
