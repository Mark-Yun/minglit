import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";

const ENV = {
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const authMockRoute = {
  matcher: (req: Request) => req.url.includes("/auth/v1/user"),
  handler: () => jsonResponse({ id: "user-test-id", email: "test@test.com" }),
};

Deno.test("settlement-register-transfers - 빈 목록: PENDING items 없으면 processed=0 반환", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authMockRoute,
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.processed, 0);
        assertEquals(payload.succeeded, 0);
        assertEquals(payload.failed, 0);
      });
    });
  });
});

Deno.test("settlement-register-transfers - 정상 처리: createOrderTransfer 호출 확인", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      authMockRoute,
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () =>
          jsonResponse([
            {
              id: "item-001",
              source_id: "event-001",
              partner_id: "partner-001",
              gross_amount: 50000,
            },
          ]),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ portone_partner_id: "portone-partner-001" }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () =>
          jsonResponse([
            { id: "app-001", payment_id: "imp_pay_001", total_amount: 50000 },
          ]),
      },
      {
        matcher: "https://api.portone.io/platform/transfers/order",
        handler: () =>
          jsonResponse({
            transfer: {
              type: "ORDER",
              id: "transfer-001",
              partnerId: "portone-partner-001",
            },
          }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.processed, 1);
        assertEquals(payload.succeeded, 1);
        assertEquals(payload.failed, 0);

        const transferCall = calls.find((c) =>
          c.url.includes("/platform/transfers/order")
        );
        assertEquals(transferCall !== undefined, true);

        const transferBody = JSON.parse(transferCall!.body!);
        assertEquals(transferBody.partnerId, "portone-partner-001");
        assertEquals(transferBody.paymentId, "imp_pay_001");
        assertEquals(transferBody.orderDetail.orderAmount, 50000);
      });
    });
  });
});

Deno.test("settlement-register-transfers - PortOne 에러: createOrderTransfer 실패 시 failed 카운트 증가", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authMockRoute,
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () =>
          jsonResponse([
            {
              id: "item-002",
              source_id: "event-002",
              partner_id: "partner-002",
              gross_amount: 30000,
            },
          ]),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ portone_partner_id: "portone-partner-002" }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () =>
          jsonResponse([
            { id: "app-002", payment_id: "imp_pay_002", total_amount: 30000 },
          ]),
      },
      {
        matcher: "https://api.portone.io/platform/transfers/order",
        handler: () =>
          jsonResponse({ message: "invalid payment" }, { status: 400 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.processed, 1);
        assertEquals(payload.succeeded, 0);
        assertEquals(payload.failed, 1);
      });
    });
  });
});

Deno.test("settlement-register-transfers - 멱등성: portone_transfer_id IS NULL 필터 적용 확인", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      authMockRoute,
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.processed, 0);

        const itemsCall = calls.find((c) =>
          c.url.includes("/rest/v1/settlement_items") && c.method === "GET"
        );
        assertEquals(itemsCall !== undefined, true);
        assertEquals(itemsCall!.url.includes("portone_transfer_id"), true);
      });
    });
  });
});
