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
  name: "event-matching - creates match pairs from two groups",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const insertedPairs = [
      { id: "mp-1", user_lower_id: "user-a", user_higher_id: "user-b" },
    ];

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "admin-1", email: "admin@test.com" }),
      },
      // existing pairs check — empty
      {
        matcher: (req) => req.url.includes("/rest/v1/match_pairs") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      // entry_groups
      {
        matcher: (req) => req.url.includes("/rest/v1/entry_groups") && req.method === "GET",
        handler: () =>
          jsonResponse([
            { id: "g-male", gender: "male" },
            { id: "g-female", gender: "female" },
          ]),
      },
      // checked-in participants
      {
        matcher: (req) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () =>
          jsonResponse([
            { id: "p-1", user_id: "user-b", entry_group_id: "g-male" },
            { id: "p-2", user_id: "user-a", entry_group_id: "g-female" },
          ]),
      },
      // insert match_pairs
      {
        matcher: (req) => req.url.includes("/rest/v1/match_pairs") && req.method === "POST",
        handler: () => jsonResponse(insertedPairs, { status: 201 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.success, true);
        assertEquals(body.match_count, 1);
        assertEquals(body.idempotent, false);
        assertEquals(body.pairs[0].user1, "user-a");
        assertEquals(body.pairs[0].user2, "user-b");
      });
    });
  },
});

Deno.test({
  name: "event-matching - returns existing pairs when already matched (idempotent)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const existingPairs = [
      { id: "mp-1", user_lower_id: "user-a", user_higher_id: "user-b" },
    ];

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "admin-1", email: "admin@test.com" }),
      },
      {
        matcher: "/rest/v1/match_pairs",
        handler: () => jsonResponse(existingPairs),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.success, true);
        assertEquals(body.idempotent, true);
        assertEquals(body.match_count, 1);
      });
    });
  },
});

Deno.test({
  name: "event-matching - returns 400 when missing event_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "admin-1", email: "admin@test.com" }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, {}),
        );
        assertEquals(response.status, 400);

        const body = await readJson(response);
        assertEquals(body.error, "Missing required parameter: event_id");
      });
    });
  },
});

Deno.test({
  name: "event-matching - returns 400 when less than 2 entry groups",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "admin-1", email: "admin@test.com" }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/match_pairs") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: "/rest/v1/entry_groups",
        handler: () => jsonResponse([{ id: "g-only", gender: "male" }]),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
        );
        assertEquals(response.status, 400);

        const body = await readJson(response);
        assertEquals(body.error, "Event must have at least 2 entry groups for matching");
      });
    });
  },
});

Deno.test({
  name: "event-matching - returns 400 when a group has no checked-in participants",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "admin-1", email: "admin@test.com" }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/match_pairs") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: "/rest/v1/entry_groups",
        handler: () =>
          jsonResponse([
            { id: "g-male", gender: "male" },
            { id: "g-female", gender: "female" },
          ]),
      },
      {
        matcher: "/rest/v1/event_participants",
        handler: () =>
          jsonResponse([
            { id: "p-1", user_id: "user-a", entry_group_id: "g-male" },
            // No female group participants
          ]),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
        );
        assertEquals(response.status, 400);

        const body = await readJson(response);
        assertEquals(body.error, "Both groups must have checked-in participants for matching");
      });
    });
  },
});

Deno.test({
  name: "event-matching - user_lower_id < user_higher_id ordering",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    // user-z from group A, user-a from group B → lower=user-a, higher=user-z
    const { fetchMock, calls } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ id: "admin-1", email: "admin@test.com" }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/match_pairs") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: "/rest/v1/entry_groups",
        handler: () =>
          jsonResponse([
            { id: "g-a", gender: "male" },
            { id: "g-b", gender: "female" },
          ]),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: () =>
          jsonResponse([
            { id: "p-1", user_id: "user-z", entry_group_id: "g-a" },
            { id: "p-2", user_id: "user-a", entry_group_id: "g-b" },
          ]),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/match_pairs") && req.method === "POST",
        handler: (req) =>
          jsonResponse(
            [{ id: "mp-1", user_lower_id: "user-a", user_higher_id: "user-z" }],
            { status: 201 },
          ),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(
          authenticatedJsonRequest(BASE_URL, { event_id: "evt-1" }),
        );
        assertEquals(response.status, 200);

        const body = await readJson(response);
        assertEquals(body.pairs[0].user1, "user-a");
        assertEquals(body.pairs[0].user2, "user-z");

        // Verify the insert call had correct ordering
        const insertCall = calls.find(
          (c) => c.url.includes("/rest/v1/match_pairs") && c.method === "POST",
        );
        const insertBody = JSON.parse(insertCall!.body!);
        assertEquals(insertBody[0].user_lower_id, "user-a");
        assertEquals(insertBody[0].user_higher_id, "user-z");
      });
    });
  },
});

Deno.test({
  name: "event-matching - OPTIONS returns CORS response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const response = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
    assertEquals(response.status, 200);
  },
});
