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

const insertRefundRequestRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/refund_requests") && req.method === "POST",
  handler: () =>
    jsonResponse({
      id: "request-123",
      application_id: "app-123",
      status: "pending",
      requested_at: "2026-06-08T00:00:00Z",
      response_deadline_at: "2026-06-11T00:00:00Z",
    }),
};

const updateApplicationRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

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
      insertRefundRequestRoute,
      updateApplicationRoute,
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
