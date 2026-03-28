import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const ENV = {
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("settlement-transfer - happy path creates transfer", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      authRoute,
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ portone_partner_id: "portone-partner-123" }),
      },
      {
        matcher: "https://api.portone.io/platform/transfers/order",
        handler: () => jsonResponse({ transfer: { type: "ORDER", id: "transfer-abc", partnerId: "portone-partner-123" } }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          partner_id: "partner-uuid",
          payment_id: "imp_123",
          order_amount: 15000,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.transfer.transfer.id, "transfer-abc");

        const transferCall = calls.find((c) => c.url.includes("/platform/transfers/order"));
        const transferBody = JSON.parse(transferCall!.body!);
        assertEquals(transferBody.partnerId, "portone-partner-123");
        assertEquals(transferBody.paymentId, "imp_123");
        assertEquals(transferBody.orderDetail.orderAmount, 15000);
      });
    });
  });
});

Deno.test("settlement-transfer - partner not synced returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ portone_partner_id: null }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          partner_id: "partner-uuid",
          payment_id: "imp_123",
          order_amount: 15000,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Partner not synced with PortOne");
      });
    });
  });
});

Deno.test("settlement-transfer - partner not found returns 404", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ error: { message: "not found" } }, { status: 406 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          partner_id: "nonexistent",
          payment_id: "imp_123",
          order_amount: 15000,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 404);
        assertEquals(payload.error, "Partner not found");
      });
    });
  });
});

Deno.test("settlement-transfer - missing required fields returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { partner_id: "partner-uuid" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required fields: partner_id, payment_id, order_amount");
      });
    });
  });
});

Deno.test("settlement-transfer - PortOne API error returns 502", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req) => req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: () => jsonResponse({ portone_partner_id: "portone-partner-123" }),
      },
      {
        matcher: "https://api.portone.io/platform/transfers/order",
        handler: () => jsonResponse({ message: "invalid payment" }, { status: 400 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          partner_id: "partner-uuid",
          payment_id: "imp_123",
          order_amount: 15000,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Failed to create order transfer");
      });
    });
  });
});
