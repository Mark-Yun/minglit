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

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
  // Valid Ed25519 test private key JWK (for testing only — not used in production)
  TICKET_SIGNING_PRIVATE_KEY_JWK: JSON.stringify({
    kty: "OKP",
    crv: "Ed25519",
    d: "nWGxne_9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A",
    x: "11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo",
  }),
};

const ENV_NO_KEY = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const BASE_URL = "http://localhost";

Deno.test({
  name: "user-get-ticket-token - returns 200 with valid token",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      // requireAuth → auth.getUser
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      // select event_applications
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () =>
          jsonResponse({
            ticket_id: "ticket-1",
            event_id: "event-1",
            user_id: "user-1",
            status: "paid",
          }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { ticket_id: "ticket-1" }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.ticket_id, "ticket-1");
        assertEquals(body.event_id, "event-1");
        assertEquals(body.user_id, "user-1");
        assertEquals(typeof body.signature, "string");
        assertEquals(typeof body.expires_at, "string");
      });
    });
  },
});

Deno.test({
  name: "user-get-ticket-token - returns 400 when ticket_id is missing",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {}),
        );
        assertEquals(response.status, 400);

        const body = await readJson(response);
        assertEquals(body.error, "Missing required parameter: ticket_id");
      });
    });
  },
});

Deno.test({
  name: "user-get-ticket-token - returns 404 when application not found",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () => jsonResponse(null),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { ticket_id: "nonexistent-ticket" }),
        );
        assertEquals(response.status, 404);

        const body = await readJson(response);
        assertEquals(body.error, "Ticket not found");
      });
    });
  },
});

Deno.test({
  name: "user-get-ticket-token - returns 500 when signing key not configured",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_applications") && req.method === "GET",
        handler: () =>
          jsonResponse({
            ticket_id: "ticket-1",
            event_id: "event-1",
            user_id: "user-1",
            status: "paid",
          }),
      },
    ]);

    await withEnv(ENV_NO_KEY, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { ticket_id: "ticket-1" }),
        );
        assertEquals(response.status, 500);

        const body = await readJson(response);
        assertEquals(body.error, "Ticket signing key not configured");
      });
    });
  },
});

Deno.test({
  name: "user-get-ticket-token - returns 401 without auth token",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = new Request(BASE_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ticket_id: "ticket-1" }),
        });

        const response = await handler(request);
        assertEquals(response.status, 401);
      });
    });
  },
});

Deno.test({
  name: "user-get-ticket-token - OPTIONS returns CORS response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
    assertEquals(response.status, 200);
  },
});
