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
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "user-request-refund",
};

const paidAt = new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString();
const eventStart = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();

function appRoute(overrides: Record<string, unknown> = {}) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/event_applications") && req.method === "GET",
    handler: () =>
      jsonResponse({
        id: "app-123",
        event_id: "event-123",
        user_id: "user-123",
        status: "paid",
        payment_id: "pay123",
        payment_amount: 20000,
        paid_at: paidAt,
        refund_status: "none",
        ...overrides,
      }),
  };
}

const eventRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/events") && req.method === "GET",
  handler: () =>
    jsonResponse({
      id: "event-123",
      party_id: "party-123",
      start_time: eventStart,
    }),
};

const policyRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/rpc/get_current_policy"),
  handler: () => jsonResponse({ grace_period_hours: 3, cutoff_days: 7 }),
};

const noExistingRequestRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/refund_requests") && req.method === "GET",
  handler: () => jsonResponse(null),
};

const partyRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/parties") && req.method === "GET",
  handler: () => jsonResponse({ partner_id: "partner-123" }),
};

const createRefundRequestRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/rpc/create_partner_refund_request") &&
    req.method === "POST",
  handler: async (req: Request) => {
    const body = await req.json();
    assertEquals(body.p_application_id, "app-123");
    assertEquals(body.p_user_id, "user-123");
    assertEquals(body.p_event_id, "event-123");
    assertEquals(body.p_partner_id, "partner-123");
    assertEquals(body.p_reason_code, "schedule_change");
    assertEquals(body.p_reason_text ?? null, null);
    return jsonResponse({
      id: "request-123",
      application_id: "app-123",
      status: "pending",
      requested_at: "2026-06-08T00:00:00Z",
      response_deadline_at: "2026-06-11T00:00:00Z",
    });
  },
};

const createRefundRequestWithTextRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/rpc/create_partner_refund_request") &&
    req.method === "POST",
  handler: async (req: Request) => {
    const body = await req.json();
    assertEquals(body.p_reason_code, "other");
    assertEquals(body.p_reason_text, "Cannot attend");
    return jsonResponse({
      id: "request-123",
      application_id: "app-123",
      status: "pending",
      requested_at: "2026-06-08T00:00:00Z",
      response_deadline_at: "2026-06-11T00:00:00Z",
    });
  },
};

function errorRoute(
  matcher: (req: Request) => boolean,
  message = "db error",
  status = 500,
) {
  return {
    matcher,
    handler: () => jsonResponse({ message, code: "XX000" }, { status }),
  };
}

async function runRefundRequest(
  routes: Parameters<typeof createFetchMock>[0],
  body: Record<string, unknown> = {
    application_id: "app-123",
    reason_code: "schedule_change",
  },
) {
  return await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute, ...routes]);

    return await withMockedFetch(
      fetchMock,
      async () =>
        await withNoIntervals(async () => {
          const response = await handler(
            authenticatedJsonRequest("http://localhost", body),
          );
          return { response, payload: await readJson(response) };
        }),
    );
  });
}

Deno.test("user-request-refund - creates partner refund request", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      appRoute(),
      eventRoute,
      policyRoute,
      noExistingRequestRoute,
      partyRoute,
      createRefundRequestRoute,
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const response = await handler(
          authenticatedJsonRequest("http://localhost", {
            application_id: "app-123",
            reason_code: "schedule_change",
          }),
        );
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.type, "partner_refund_requested");
        assertEquals(payload.request.id, "request-123");
        assertEquals(payload.request.status, "pending");
      });
    });
  });
});

Deno.test("user-request-refund - automatic refund eligible returns 409", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute,
      appRoute({ paid_at: new Date().toISOString() }),
      eventRoute,
      policyRoute,
      noExistingRequestRoute,
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const response = await handler(
          authenticatedJsonRequest("http://localhost", {
            application_id: "app-123",
            reason_code: "health",
          }),
        );
        const payload = await readJson(response);

        assertEquals(response.status, 409);
        assertEquals(payload.error, "automatic_refund_available");
      });
    });
  });
});

Deno.test("user-request-refund - validates input", async () => {
  const invalidReason = await runRefundRequest([], {
    application_id: "app-123",
    reason_code: "bad",
  });
  assertEquals(invalidReason.response.status, 400);
  assertEquals(invalidReason.payload.error, "Invalid field: reason_code");

  const invalidText = await runRefundRequest([], {
    application_id: "app-123",
    reason_code: "other",
    reason_text: 123,
  });
  assertEquals(invalidText.response.status, 400);
  assertEquals(invalidText.payload.error, "Invalid field: reason_text");

  const withText = await runRefundRequest([
    appRoute(),
    eventRoute,
    policyRoute,
    noExistingRequestRoute,
    partyRoute,
    createRefundRequestWithTextRoute,
  ], {
    application_id: "app-123",
    reason_code: "other",
    reason_text: "Cannot attend",
  });
  assertEquals(withText.response.status, 200);
});

Deno.test("user-request-refund - application guards", async () => {
  const notFound = await runRefundRequest([
    errorRoute((req) =>
      req.url.includes("/rest/v1/event_applications") && req.method === "GET"
    ),
  ]);
  assertEquals(notFound.response.status, 404);
  assertEquals(notFound.payload.error, "Order not found");

  const forbidden = await runRefundRequest([appRoute({ user_id: "other" })]);
  assertEquals(forbidden.response.status, 403);

  const invalidStatus = await runRefundRequest([
    appRoute({ status: "pending" }),
  ]);
  assertEquals(invalidStatus.response.status, 400);
  assertEquals(invalidStatus.payload.details.reason, "invalid_status");

  const notPaid = await runRefundRequest([
    appRoute({ payment_amount: 0, payment_id: null }),
  ]);
  assertEquals(notPaid.response.status, 400);
  assertEquals(notPaid.payload.details.reason, "not_paid_order");

  const alreadyRefunded = await runRefundRequest([
    appRoute({ refund_status: "completed" }),
  ]);
  assertEquals(alreadyRefunded.response.status, 409);
  assertEquals(alreadyRefunded.payload.error, "refund_request_exists");
});

Deno.test("user-request-refund - dependency failures and duplicates", async () => {
  const duplicate = await runRefundRequest([
    appRoute(),
    eventRoute,
    policyRoute,
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/refund_requests") && req.method === "GET",
      handler: () =>
        jsonResponse({ id: "request-existing", status: "pending" }),
    },
  ]);
  assertEquals(duplicate.response.status, 409);

  const eventFailure = await runRefundRequest([
    appRoute(),
    errorRoute((req) =>
      req.url.includes("/rest/v1/events") && req.method === "GET"
    ),
    policyRoute,
    noExistingRequestRoute,
  ]);
  assertEquals(eventFailure.response.status, 500);
  assertEquals(
    eventFailure.payload.error,
    "Failed to verify refund eligibility",
  );

  const policyFailure = await runRefundRequest([
    appRoute(),
    eventRoute,
    errorRoute((req) => req.url.includes("/rest/v1/rpc/get_current_policy")),
    noExistingRequestRoute,
  ]);
  assertEquals(policyFailure.response.status, 500);
  assertEquals(
    policyFailure.payload.error,
    "Failed to verify refund eligibility",
  );

  const partyFailure = await runRefundRequest([
    appRoute(),
    eventRoute,
    policyRoute,
    noExistingRequestRoute,
    errorRoute((req) =>
      req.url.includes("/rest/v1/parties") && req.method === "GET"
    ),
  ]);
  assertEquals(partyFailure.response.status, 500);
  assertEquals(partyFailure.payload.error, "Failed to create refund request");
});

Deno.test("user-request-refund - transactional rpc write failures", async () => {
  const rpcConflict = await runRefundRequest([
    appRoute(),
    eventRoute,
    policyRoute,
    noExistingRequestRoute,
    partyRoute,
    {
      matcher: (req: Request) =>
        req.url.includes("/rest/v1/rpc/create_partner_refund_request") &&
        req.method === "POST",
      handler: () => jsonResponse({ code: "23505" }, { status: 409 }),
    },
  ]);
  assertEquals(rpcConflict.response.status, 409);
  assertEquals(rpcConflict.payload.error, "refund_request_exists");

  const rpcFailure = await runRefundRequest([
    appRoute(),
    eventRoute,
    policyRoute,
    noExistingRequestRoute,
    partyRoute,
    errorRoute((req) =>
      req.url.includes("/rest/v1/rpc/create_partner_refund_request") &&
      req.method === "POST"
    ),
  ]);
  assertEquals(rpcFailure.response.status, 500);
  assertEquals(rpcFailure.payload.error, "Failed to create refund request");
});
