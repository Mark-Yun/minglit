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

Deno.test("settlement-query - settlements type returns settlement list", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.portone.io/platform/partner-settlements",
        handler: () => jsonResponse({ settlements: [{ id: "s1", amount: 10000 }], page: { number: 0, size: 10 } }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { type: "settlements" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.settlements.length, 1);
        assertEquals(payload.settlements[0].id, "s1");
      });
    });
  });
});

Deno.test("settlement-query - payouts type returns payout list", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.portone.io/platform/payouts",
        handler: () => jsonResponse({ payouts: [{ id: "p1", amount: 50000 }], page: { number: 0, size: 10 } }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { type: "payouts" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.payouts.length, 1);
        assertEquals(payload.payouts[0].id, "p1");
      });
    });
  });
});

Deno.test("settlement-query - missing type returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { partner_id: "partner-uuid" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing or invalid type: must be 'settlements' or 'payouts'");
      });
    });
  });
});

Deno.test("settlement-query - PortOne API error returns 502", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.portone.io/platform/partner-settlements",
        handler: () => jsonResponse({ message: "unauthorized" }, { status: 401 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", { type: "settlements" });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 502);
        assertEquals(payload.error, "Failed to fetch settlements");
      });
    });
  });
});
