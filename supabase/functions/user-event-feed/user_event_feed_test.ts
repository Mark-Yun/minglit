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

// Fix #1748: rate limit count HEAD response — PostgREST Content-Range format
function rateLimitCountResponse(count: number): Response {
  const contentRange = count === 0 ? "*/0" : `0-${count - 1}/${count}`;
  return new Response(null, { status: 200, headers: { "Content-Range": contentRange } });
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
  name: "user-event-feed - nearby search inserts location_access_log row",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
      // Fix #1748: HEAD = rate limit count check (0 entries → under limit)
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/location_access_log") && req.method === "HEAD",
        handler: () => rateLimitCountResponse(0),
      },
      // POST = actual INSERT of access log row
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/location_access_log") && req.method === "POST",
        handler: () => jsonResponse([], { status: 201 }),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/rpc/user_event_feed"),
        handler: () => jsonResponse(rpcFeedResponse([])),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            sort_by: "nearest_date",
            filters: { nearby: { lat: 37.5, lng: 127.0, radius_km: 5 } },
          }),
        );
        assertEquals(response.status, 200);

        // Fix #1748: match POST (INSERT), not HEAD (rate limit check)
        const logCall = calls.find((c) =>
          c.url.includes("/rest/v1/location_access_log") && c.method === "POST"
        );
        assertEquals(logCall !== undefined, true, "location_access_log INSERT was called");

        const body = JSON.parse(logCall!.body!);
        assertEquals(body.purpose, "nearby_search");
        assertEquals("lat" in body, false, "GPS coordinates not stored");
        assertEquals("lng" in body, false, "GPS coordinates not stored");
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - non-nearby request does not insert location_access_log",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock, calls } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/rpc/user_event_feed"),
        handler: () => jsonResponse(rpcFeedResponse([])),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          jsonRequest(BASE_URL, { sort_by: "recommended" }),
        );
        assertEquals(response.status, 200);

        const logCall = calls.find((c) => c.url.includes("/rest/v1/location_access_log"));
        assertEquals(logCall, undefined, "no location_access_log INSERT for non-nearby request");
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - location_access_log INSERT failure returns 500",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
      // Fix #1748: HEAD rate limit check fails → fails-open (warn + proceed)
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/location_access_log") && req.method === "HEAD",
        handler: () => new Response(null, { status: 500 }),
      },
      // POST INSERT fails → 500 returned to caller (§16 legal obligation)
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/location_access_log") && req.method === "POST",
        handler: () => jsonResponse({ message: "DB error" }, { status: 500 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            sort_by: "nearest_date",
            filters: { nearby: { lat: 37.5, lng: 127.0, radius_km: 5 } },
          }),
        );
        assertEquals(response.status, 500, "location_access_log INSERT failure returns 500");
      });
    });
  },
});

// ── Fix #1748: new security tests ────────────────────────────────────

Deno.test({
  name: "user-event-feed - anonymous nearby request returns 401",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ error: "not authenticated" }, { status: 401 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        // No Authorization header — requireAuth should reject
        const response = await handler(
          jsonRequest(BASE_URL, {
            sort_by: "nearest_date",
            filters: { nearby: { lat: 37.5, lng: 127.0, radius_km: 5 } },
          }),
        );
        assertEquals(response.status, 401, "unauthenticated nearby returns 401");
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - nearby with invalid shape returns 400",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        // lat out of [-90, 90] range
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            sort_by: "nearest_date",
            filters: { nearby: { lat: 999, lng: 127.0, radius_km: 5 } },
          }),
        );
        assertEquals(response.status, 400, "invalid lat returns 400");
        const body = await readJson(response);
        assertEquals(body.error.includes("Invalid nearby filter"), true);
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - nearby with radius_km > 50 returns 400",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            sort_by: "nearest_date",
            filters: { nearby: { lat: 37.5, lng: 127.0, radius_km: 100 } },
          }),
        );
        assertEquals(response.status, 400, "radius_km > 50 returns 400");
        const body = await readJson(response);
        assertEquals(body.error.includes("Invalid nearby filter"), true);
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - rate limit exceeded returns 429",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("/auth/v1/user"),
        handler: () => jsonResponse({ id: "user-123" }),
      },
      // Fix #1748: HEAD returns count=30 (at limit) → 429
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/location_access_log") && req.method === "HEAD",
        handler: () => rateLimitCountResponse(30),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {
            sort_by: "nearest_date",
            filters: { nearby: { lat: 37.5, lng: 127.0, radius_km: 5 } },
          }),
        );
        assertEquals(response.status, 429, "rate limit exceeded returns 429");
        const body = await readJson(response);
        assertEquals(body.error.includes("Rate limit exceeded"), true);
      });
    });
  },
});

Deno.test({
  name: "user-event-feed - OPTIONS returns CORS response",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
    assertEquals(response.status, 200);
  },
});

Deno.test({
  name: "user-event-feed - GET method returns 405",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "GET" }));
    assertEquals(response.status, 405);
  },
});
