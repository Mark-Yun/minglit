import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const ENV = {
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "settlement-query",
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const TEST_PARTNER_ID = "bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbbb";
const TEST_PORTONE_PARTNER_ID = "portone-partner-001";

function permissionRoute(hasPermission = true) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse(
        hasPermission
          ? { role: "manager", permissions: ["SETTLEMENT_VIEW"] }
          : null,
      ),
  };
}

function partnerRoute(portonePartnerId: string | null = TEST_PORTONE_PARTNER_ID) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/partners") && req.method === "GET",
    handler: () => jsonResponse({ portone_partner_id: portonePartnerId }),
  };
}

Deno.test("settlement-query - settlements type returns settlement list", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      authRoute,
      permissionRoute(),
      partnerRoute(),
      {
        matcher: "https://api.portone.io/platform/partner-settlements",
        handler: () => jsonResponse({ settlements: [{ id: "s1", amount: 10000 }], page: { number: 0, size: 10 } }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { type: "settlements", partner_id: TEST_PARTNER_ID });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 200);
      assertEquals(payload.success, true);
      assertEquals(payload.settlements.length, 1);
      assertEquals(payload.settlements[0].id, "s1");

      const portoneCall = calls.find((call) => call.url.includes("/platform/partner-settlements"));
      assertEquals(portoneCall?.url.includes(TEST_PORTONE_PARTNER_ID), true);
      assertEquals(portoneCall?.url.includes(TEST_PARTNER_ID), false);
    });
  });
});

Deno.test("settlement-query - payouts type returns payout list", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      authRoute,
      permissionRoute(),
      partnerRoute(),
      {
        matcher: "https://api.portone.io/platform/payouts",
        handler: () => jsonResponse({ payouts: [{ id: "p1", amount: 50000 }], page: { number: 0, size: 10 } }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { type: "payouts", partner_id: TEST_PARTNER_ID });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 200);
      assertEquals(payload.success, true);
      assertEquals(payload.payouts.length, 1);
      assertEquals(payload.payouts[0].id, "p1");

      const portoneCall = calls.find((call) => call.url.includes("/platform/payouts"));
      assertEquals(portoneCall?.url.includes(TEST_PORTONE_PARTNER_ID), true);
      assertEquals(portoneCall?.url.includes(TEST_PARTNER_ID), false);
    });
  });
});

Deno.test("settlement-query - missing type returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { partner_id: "partner-uuid" });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 400);
      assertEquals(payload.error, "Missing or invalid type: must be 'settlements' or 'payouts'");
    });
  });
});

Deno.test("settlement-query - missing partner_id returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { type: "settlements" });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 400);
      assertEquals(payload.error, "Missing partner_id");
    });
  });
});

Deno.test("settlement-query - missing settlement permission returns 403", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute, permissionRoute(false)]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { type: "settlements", partner_id: TEST_PARTNER_ID });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 403);
      assertEquals(payload.error, "Forbidden: insufficient partner permissions");
    });
  });
});

Deno.test("settlement-query - partner not synced returns 400", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute, permissionRoute(), partnerRoute(null)]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { type: "settlements", partner_id: TEST_PARTNER_ID });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 400);
      assertEquals(payload.error, "Partner not synced with PortOne");
    });
  });
});

Deno.test("settlement-query - PortOne API error returns 502", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      authRoute,
      permissionRoute(),
      partnerRoute(),
      {
        matcher: "https://api.portone.io/platform/partner-settlements",
        handler: () => jsonResponse({ message: "unauthorized" }, { status: 401 }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      const request = authenticatedJsonRequest("http://localhost", { type: "settlements", partner_id: TEST_PARTNER_ID });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 502);
      assertEquals(payload.error, "Failed to fetch settlements");
    });
  });
});
