import { assertEquals } from "@std/assert";
import { stub } from "@std/testing/mock";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { mockVectorInteractionMessage, mockVectorPartyMessage } from "../_test_utils/fixtures.ts";
import { OpenAIService } from "./openai_service.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";

function embedding(value: number, size = 3) {
  return new Array(size).fill(value);
}

Deno.test({
  name: "vector-worker - processes party message",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIService.prototype, "generateEmbeddings", async () => [embedding(0.1)]),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockVectorPartyMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/party_embeddings") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_delete"),
      handler: () => jsonResponse({}),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(jsonRequest("http://localhost", {}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            assertEquals(payload.processed, 1);
          });
        });
      },
    );
  } finally {
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "vector-worker - processes interaction message",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIService.prototype, "generateEmbeddings", async () => []),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockVectorInteractionMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_embeddings") && req.method === "GET",
      handler: () => jsonResponse({ embedding: embedding(0) }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/party_embeddings") && req.method === "GET",
      handler: () => jsonResponse({ embedding: embedding(0.2) }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_embeddings") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_delete"),
      handler: () => jsonResponse({}),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(jsonRequest("http://localhost", {}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            assertEquals(payload.processed, 1);
          });
        });
      },
    );
  } finally {
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "vector-worker - empty queue returns processed 0",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIService.prototype, "generateEmbeddings", async () => []),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([]),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(jsonRequest("http://localhost", {}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            assertEquals(payload.processed, 0);
          });
        });
      },
    );
  } finally {
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "vector-worker - missing env returns 500",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: undefined,
      SUPABASE_SERVICE_ROLE_KEY: undefined,
      OPENAI_API_KEY: undefined,
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

Deno.test({
  name: "vector-worker - openai error returns processed 0",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIService.prototype, "generateEmbeddings", async () => {
      throw new Error("OpenAI failure");
    }),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockVectorPartyMessage]),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(jsonRequest("http://localhost", {}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            assertEquals(payload.processed, 0);
          });
        });
      },
    );
  } finally {
    stubs.forEach((s) => s.restore());
  }
  },
});
