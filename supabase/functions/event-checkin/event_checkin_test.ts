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
};

const BASE_URL = "http://localhost";

Deno.test({
  name: "event-checkin - returns 200 and checks in participant",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      // auth.getUser
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "user-1", email: "test@test.com" }),
      },
      // select participant
      {
        matcher: (req) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () =>
          jsonResponse({
            id: "part-1",
            event_id: "evt-1",
            user_id: "user-1",
            status: "ticket_issued",
          }),
      },
      // update participant
      {
        matcher: (req) => req.url.includes("/rest/v1/event_participants") && req.method === "PATCH",
        handler: () => new Response(null, { status: 204 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            event_id: "evt-1",
            participant_id: "part-1",
          }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.success, true);
        assertEquals(body.status, "checked_in");
        assertEquals(body.participant_id, "part-1");
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 400 when missing parameters",
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
          authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
        );
        assertEquals(response.status, 400);

        const body = await readJson(response);
        assertEquals(body.error, "Missing required parameters: event_id, participant_id");
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 404 when participant not found",
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
        matcher: "/rest/v1/event_participants",
        handler: () => jsonResponse(null),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            event_id: "evt-1",
            participant_id: "nonexistent",
          }),
        );
        assertEquals(response.status, 404);

        const body = await readJson(response);
        assertEquals(body.error, "Participant not found");
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 403 when caller is not the participant",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "other-user", email: "other@test.com" }),
      },
      {
        matcher: "/rest/v1/event_participants",
        handler: () =>
          jsonResponse({
            id: "part-1",
            event_id: "evt-1",
            user_id: "user-1",
            status: "ticket_issued",
          }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            event_id: "evt-1",
            participant_id: "part-1",
          }),
        );
        assertEquals(response.status, 403);

        const body = await readJson(response);
        assertEquals(body.error, "Forbidden: caller is not the participant's user");
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 409 when already checked in",
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
        matcher: "/rest/v1/event_participants",
        handler: () =>
          jsonResponse({
            id: "part-1",
            event_id: "evt-1",
            user_id: "user-1",
            status: "checked_in",
          }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            event_id: "evt-1",
            participant_id: "part-1",
          }),
        );
        assertEquals(response.status, 409);

        const body = await readJson(response);
        assertEquals(body.error, "Participant already checked in");
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 400 when status is not ticket_issued",
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
        matcher: "/rest/v1/event_participants",
        handler: () =>
          jsonResponse({
            id: "part-1",
            event_id: "evt-1",
            user_id: "user-1",
            status: "cancelled",
          }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            event_id: "evt-1",
            participant_id: "part-1",
          }),
        );
        assertEquals(response.status, 400);

        const body = await readJson(response);
        assertEquals(body.error, "Cannot check in participant with status 'cancelled'");
      });
    });
  },
});

Deno.test({
  name: "event-checkin - returns 401 without auth token",
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
          body: JSON.stringify({ event_id: "evt-1", participant_id: "part-1" }),
        });

        const response = await handler(request);
        assertEquals(response.status, 401);
      });
    });
  },
});

Deno.test({
  name: "event-checkin - OPTIONS returns CORS response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
    assertEquals(response.status, 200);
  },
});
