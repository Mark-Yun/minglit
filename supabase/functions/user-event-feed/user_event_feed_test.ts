import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonRequest,
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

// ── Helper: mock RPC response ────────────────────────────────────────

function rpcFeedResponse(events: unknown[] = [], hasMore = false) {
  return {
    events,
    has_more: hasMore,
    next_cursor: hasMore ? { sort_key: "2026-03-30T00:00:00Z", id: "evt-1" } : null,
  };
}

function createFeedFetchMock(rpcResult: unknown, authUser?: { id: string } | null) {
  return createFetchMock([
    // Auth endpoint — for optionalAuth
    ...(authUser !== undefined ? [{
      matcher: (req: Request) => req.url.includes("/auth/v1/user"),
      handler: () =>
        authUser
          ? jsonResponse(authUser)
          : jsonResponse({ error: "invalid" }, { status: 401 }),
    }] : []),
    // RPC endpoint
    {
      matcher: (req: Request) => req.url.includes("/rest/v1/rpc/user_event_feed"),
      handler: () => jsonResponse(rpcResult),
    },
  ]);
}

// ── Tests ────────────────────────────────────────────────────────────

Deno.test({
  name: "user-event-feed - valid request with recommended sort returns 200",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const mockEvents = [
      { id: "evt-1", title: "Party A", start_time: "2026-04-01T18:00:00Z" },
      { id: "evt-2", title: "Party B", start_time: "2026-04-02T18:00:00Z" },
    ];

    const { fetchMock } = createFeedFetchMock(
      rpcFeedResponse(mockEvents, false),
      { id: "user-123" },
    );

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            sort_by: "recommended",
            limit: 20,
          }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.events.length, 2);
        assertEquals(body.has_more, false);
        assertEquals(body.sort_by, "recommended");
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - anonymous request returns 200 with basic feed",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const mockEvents = [
      { id: "evt-1", title: "Public Party" },
    ];

    const { fetchMock } = createFeedFetchMock(
      rpcFeedResponse(mockEvents),
    );

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        // No Authorization header
        const response = await handler(
          jsonRequest(BASE_URL, { sort_by: "recommended" }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.events.length, 1);
        assertEquals(body.sort_by, "recommended");
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - invalid sort_by returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv(ENV, async () => {
      const response = await handler(
        jsonRequest(BASE_URL, { sort_by: "invalid_sort" }),
      );
      assertEquals(response.status, 400);

      const body = await readJson(response);
      assertEquals(body.error.includes("Invalid sort_by"), true);
    });
  },
});

Deno.test({
  name: "user-event-feed - invalid cursor returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv(ENV, async () => {
      const response = await handler(
        jsonRequest(BASE_URL, {
          sort_by: "recommended",
          cursor: { bad_field: "oops" },
        }),
      );
      assertEquals(response.status, 400);

      const body = await readJson(response);
      assertEquals(body.error.includes("Invalid cursor"), true);
    });
  },
});

Deno.test({
  name: "user-event-feed - pagination with cursor returns next page",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const mockEvents = [
      { id: "evt-3", title: "Party C" },
    ];

    const { fetchMock, calls } = createFeedFetchMock(
      rpcFeedResponse(mockEvents, false),
    );

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          jsonRequest(BASE_URL, {
            sort_by: "recommended",
            cursor: { sort_key: "2026-03-30T00:00:00Z", id: "evt-2" },
            limit: 10,
          }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.events.length, 1);
        assertEquals(body.has_more, false);

        // Verify RPC was called with cursor params
        const rpcCall = calls.find((c) => c.url.includes("/rest/v1/rpc/user_event_feed"));
        const rpcBody = JSON.parse(rpcCall!.body!);
        assertEquals(rpcBody.p_cursor_sort_key, "2026-03-30T00:00:00Z");
        assertEquals(rpcBody.p_cursor_id, "evt-2");
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - OPTIONS returns CORS response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
    assertEquals(response.status, 200);
  },
});

Deno.test({
  name: "user-event-feed - GET method returns 405",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "GET" }));
    assertEquals(response.status, 405);
  },
});
