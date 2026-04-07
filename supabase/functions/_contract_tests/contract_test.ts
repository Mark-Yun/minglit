/**
 * Contract tests: validate Edge Function responses against shared JSON schemas.
 *
 * If an Edge Function changes a response field, this test fails — preventing
 * silent breakage of the Flutter client.
 */
import { assertEquals } from "@std/assert";
import { assertMatchesSchema, validateSchema } from "../_test_utils/schema_validator.ts";
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
import {
  authRoute,
  mockOrder,
  mockPaidPayment,
  mockPortoneVerification,
  mockQueueUpdateMessage,
} from "../_test_utils/fixtures.ts";

// ── Schema & sample loaders ──────────────────────────────────────────

const schemasDir = new URL("../../../shared/schemas/", import.meta.url);

async function loadSchema(name: string): Promise<Record<string, unknown>> {
  const path = new URL(`responses/${name}.json`, schemasDir);
  return JSON.parse(await Deno.readTextFile(path));
}

async function loadSample(name: string): Promise<unknown> {
  const path = new URL(`samples/${name}.json`, schemasDir);
  return JSON.parse(await Deno.readTextFile(path));
}

// ── Sample files conform to schemas ──────────────────────────────────

Deno.test("contract: sample payment_verify_success matches schema", async () => {
  const schema = await loadSchema("payment_verify");
  const sample = await loadSample("payment_verify_success");
  assertMatchesSchema(sample, schema, "payment_verify_success sample");
});

Deno.test("contract: sample payment_cancel_success matches schema", async () => {
  const schema = await loadSchema("payment_cancel");
  const sample = await loadSample("payment_cancel_success");
  assertMatchesSchema(sample, schema, "payment_cancel_success sample");
});

Deno.test("contract: sample settlement_query_settlements matches schema", async () => {
  const schema = await loadSchema("settlement_query");
  const sample = await loadSample("settlement_query_settlements");
  assertMatchesSchema(sample, schema, "settlement_query_settlements sample");
});

Deno.test("contract: sample settlement_query_payouts matches schema", async () => {
  const schema = await loadSchema("settlement_query");
  const sample = await loadSample("settlement_query_payouts");
  assertMatchesSchema(sample, schema, "settlement_query_payouts sample");
});

Deno.test("contract: sample identity_verify_success matches schema", async () => {
  const schema = await loadSchema("identity_verify");
  const sample = await loadSample("identity_verify_success");
  assertMatchesSchema(sample, schema, "identity_verify_success sample");
});

// ── Error response schema ────────────────────────────────────────────

Deno.test("contract: error response schema validates standard errors", async () => {
  const schema = await loadSchema("error");
  assertMatchesSchema({ error: "Something went wrong" }, schema, "simple error");
  assertMatchesSchema({ error: "Bad", details: { code: 123 } }, schema, "error with details");
  const invalid = validateSchema({ message: "wrong shape" }, schema);
  assertEquals(invalid.length > 0, true, "should reject non-conforming error");
});

// ── Live Edge Function response validation ───────────────────────────

const COMMON_ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
  PORTONE_V2_API_KEY: "test-v2-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

Deno.test("contract: payment-verify response matches schema", async () => {
  const schema = await loadSchema("payment_verify");

  await withEnv(COMMON_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../payment-verify/index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/imp_contract",
        handler: () => jsonResponse({ code: 0, response: { ...mockPaidPayment, merchant_uid: "order-contract" } }),
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
        const req = authenticatedJsonRequest("http://localhost", {
          imp_uid: "imp_contract",
          merchant_uid: "order-contract",
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const payload = await readJson(res);
        assertMatchesSchema(payload, schema, "payment-verify live response");
      });
    });
  });
});

Deno.test("contract: identity-verify response matches schema", async () => {
  const schema = await loadSchema("identity_verify");

  await withEnv(COMMON_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../identity-verify/index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "api.portone.io",
        handler: () => jsonResponse(mockPortoneVerification),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/update_user_identity") && req.method === "POST",
        handler: () => jsonResponse(null),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          identity_verification_id: "iv_test_123",
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const payload = await readJson(res);
        assertMatchesSchema(payload, schema, "identity-verify live response");
      });
    });
  });
});

Deno.test("contract: payment-cancel response matches schema", async () => {
  const schema = await loadSchema("payment_cancel");

  const nowMs = Date.now();
  const eligiblePaidAt = new Date(nowMs - 1 * 60 * 60 * 1000).toISOString();
  const farFutureEvent = new Date(nowMs + 10 * 24 * 60 * 60 * 1000).toISOString();

  await withEnv(COMMON_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../payment-cancel/index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () =>
          jsonResponse({
            paid_at: eligiblePaidAt,
            event_id: "event-123",
            refund_status: "none",
            user_id: "user-123",
          }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: () => jsonResponse({ start_time: farFutureEvent }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/rpc/get_current_policy") && req.method === "POST",
        handler: () => jsonResponse({ grace_period_hours: 2, cutoff_days: 7 }),
      },
      {
        matcher: "https://api.iamport.kr/users/getToken",
        handler: () => jsonResponse({ code: 0, response: { access_token: "token" } }),
      },
      {
        matcher: "https://api.iamport.kr/payments/cancel",
        handler: () =>
          jsonResponse({ code: 0, response: { status: "cancelled", amount: 15000 } }),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
        handler: () => jsonResponse({}),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          payment_id: "imp_contract_cancel",
          reason: "contract test",
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const payload = await readJson(res);
        assertMatchesSchema(payload, schema, "payment-cancel live response");
      });
    });
  });
});

Deno.test("contract: settlement-query response matches schema", async () => {
  const schema = await loadSchema("settlement_query");

  await withEnv(COMMON_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../settlement-query/index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      {
        matcher: "https://api.portone.io/platform/partner-settlements",
        handler: () =>
          jsonResponse({
            settlements: [
              {
                id: "s1",
                partnerId: "p1",
                transferId: "t1",
                amount: 10000,
                currency: "KRW",
                settlementDate: "2026-03-20",
              },
            ],
            page: { number: 0, size: 10 },
          }),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          type: "settlements",
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const payload = await readJson(res);
        assertMatchesSchema(payload, schema, "settlement-query live response");
      });
    });
  });
});

Deno.test("contract: payment-verify error matches error schema", async () => {
  const schema = await loadSchema("error");

  await withEnv(COMMON_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("../payment-verify/index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const req = authenticatedJsonRequest("http://localhost", {});
        const res = await handler(req);
        assertEquals(res.status, 400);
        const payload = await readJson(res);
        assertMatchesSchema(payload, schema, "payment-verify error response");
      });
    });
  });
});
