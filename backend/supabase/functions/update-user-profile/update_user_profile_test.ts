import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { mockQueueUpdateMessage } from "../_test_utils/fixtures.ts";

Deno.test({
  name: "update-user-profile - processes queue message",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_pop"),
      handler: () => jsonResponse([mockQueueUpdateMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_embeddings") && req.method === "GET",
      handler: () => jsonResponse({ embedding: [0, 0, 0] }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/party_embeddings") && req.method === "GET",
      handler: () => jsonResponse({ embedding: [0.1, 0.2, 0.3] }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_embeddings") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(new Request("http://localhost"));
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.processed.user_id, "user-1");
          assertEquals(payload.processed.action_type, "like");
          assertEquals(payload.processed.weight, 3);
        });
      });
    },
  );
  },
});

Deno.test({
  name: "update-user-profile - queue empty returns 200",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_pop"),
      handler: () => jsonResponse([]),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(new Request("http://localhost"));
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.message, "Queue is empty");
        });
      });
    },
  );
  },
});

Deno.test({
  name: "update-user-profile - missing party embedding returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_pop"),
      handler: () => jsonResponse([mockQueueUpdateMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_embeddings") && req.method === "GET",
      handler: () => jsonResponse({ embedding: [0, 0, 0] }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/party_embeddings") && req.method === "GET",
      handler: () => jsonResponse(null),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(new Request("http://localhost"));
          const payload = await readJson(response);

          assertEquals(response.status, 404);
          assertEquals(payload.error, "Party embedding missing");
        });
      });
    },
  );
  },
});

Deno.test({
  name: "update-user-profile - queue error returns 500",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_pop"),
      handler: () => jsonResponse({ message: "error" }, { status: 500 }),
    },
  ]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(new Request("http://localhost"));
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(typeof payload.error, "string");
        });
      });
    },
  );
  },
});
