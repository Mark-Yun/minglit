import { assertEquals, assertThrows } from "@std/assert";
import { stub } from "@std/testing/mock";
import { HybridCalculator } from "./calculator.ts";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { mockVectorInteractionMessage, mockVectorPartyMessage } from "../_test_utils/fixtures.ts";
import { OpenAIEmbedding } from "../_shared/ai/adapters/openai_embedding.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";

function makeRequest(body: unknown): Request {
  return new Request("http://localhost", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer service-key",
    },
    body: JSON.stringify(body),
  });
}

function embedding(value: number, size = 3) {
  return new Array(size).fill(value);
}

Deno.test({
  name: "ai-embed - processes party message",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => [embedding(0.1)]),
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
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
  name: "ai-embed - processes interaction message",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
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
  name: "ai-embed - empty queue returns processed 0",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
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
  name: "ai-embed - missing env returns 500",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "ai-embed",
      SUPABASE_URL: undefined,
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
      OPENAI_API_KEY: undefined,
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(makeRequest({}));
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
  // Fix #1441: 파티 벡터화 에러는 더 이상 삼키지 않고 500으로 전파 — PGMQ retry 활용
  name: "ai-embed - embedding error returns 500",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => {
      throw new Error("Embedding provider failure");
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
            const payload = await readJson(response);

            assertEquals(response.status, 500);
            assertEquals(typeof payload.error, "string");
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
  // Fix #1441: user_embeddings DB 쿼리 에러 시 해당 task만 스킵하고 processed: 0 반환
  name: "ai-embed - user_embeddings db error skips interaction task",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
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
      handler: () => jsonResponse({ message: "DB connection error" }, { status: 500 }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/party_embeddings") && req.method === "GET",
      handler: () => jsonResponse({ embedding: embedding(0.2) }),
    },
  ]);

  try {
    await withEnv(
      {
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
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
  // Fix #1441: party_embeddings DB 쿼리 에러 시 해당 task만 스킵하고 processed: 0 반환
  name: "ai-embed - party_embeddings db error skips interaction task",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
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
      handler: () => jsonResponse({ message: "DB connection error" }, { status: 500 }),
    },
  ]);

  try {
    await withEnv(
      {
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
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
  name: "ai-embed - unauthorized: no auth header returns 401",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "ai-embed",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
      OPENAI_API_KEY: "openai-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(new Request("http://localhost", { method: "POST" }));
          assertEquals(response.status, 401);
        });
      });
    },
  );
  },
});

Deno.test({
  name: "ai-embed - unauthorized: wrong token returns 401",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "ai-embed",
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
      OPENAI_API_KEY: "openai-key",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(new Request("http://localhost", {
            method: "POST",
            headers: { "Authorization": "Bearer bad-key" },
          }));
          assertEquals(response.status, 401);
        });
      });
    },
  );
  },
});

Deno.test({
  // Fix #1441: HybridCalculator 벡터 차원 불일치 시 에러 발생
  name: "HybridCalculator - throws on vector dimension mismatch",
  fn: () => {
    const calculator = new HybridCalculator({ decayRate: 0.05 });
    assertThrows(
      () => calculator.calculate([0.1, 0.2, 0.3], [0.1, 0.2], 0.5),
      Error,
      "Vector dimension mismatch",
    );
  },
});

Deno.test({
  // Fix #1472: EF-ERR-01: pgmq_read DB 에러 발생 시 throw + 500 반환 → PGMQ retry 트리거
  name: "ai-embed - pgmq_read DB error returns 500 for PGMQ retry",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse({ message: "DB connection error", code: "PGRST301" }, { status: 500 }),
    },
  ]);

  try {
    await withEnv(
      {
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
            const payload = await readJson(response);

            // DB error thrown → 500 returned, message NOT deleted from queue → PGMQ retry
            assertEquals(response.status, 500);
            assertEquals(typeof payload.error, "string");
            // markProcessed and moveToDLQ must NOT be called — message stays in queue for retry
            assertEquals(stubs[1].calls.length, 0, "markProcessed must not be called on DB error");
            assertEquals(stubs[2].calls.length, 0, "moveToDLQ must not be called on DB read error");
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
  // Fix #1472: EF-ERR-02: read_ct > 5인 메시지 → moveToDLQ 호출 (vectorization 반복 실패 후 DLQ)
  name: "ai-embed - message with read_ct > 5 moves to DLQ",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const highReadCtMessage = { ...mockVectorPartyMessage, read_ct: 6 };

  const moveToDLQStub = stub(WorkerUtils.prototype, "moveToDLQ", async () => {});
  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    moveToDLQStub,
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([highReadCtMessage]),
    },
  ]);

  try {
    await withEnv(
      {
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
            const payload = await readJson(response);

            // Message moved to DLQ — not counted as processed, not deleted from main queue
            assertEquals(response.status, 200);
            assertEquals(payload.processed, 0);
            assertEquals(moveToDLQStub.calls.length, 1);
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
  // Fix #1472: EF-ERR-03: 실제 프로덕션 차원 불일치 (OpenAI 1536 vs 768) → 명시적 에러 메시지
  name: "HybridCalculator - throws with explicit message on 1536 vs 768 dimension mismatch",
  fn: () => {
    const calculator = new HybridCalculator({ decayRate: 0.05 });
    assertThrows(
      () => calculator.calculate(new Array(1536).fill(0), new Array(768).fill(0.1), 0.5),
      Error,
      "Vector dimension mismatch: oldVector(1536) !== actionVector(768)",
    );
  },
});

Deno.test({
  // Fix #1472: EF-ERR-04: 500 에러 시 Axiom structured log (function, level, message) 포함 확인
  name: "ai-embed - 500 error emits structured error log with function prefix",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
    stub(OpenAIEmbedding.prototype, "generateEmbeddings", async () => []),
  ];

  const errorLogs: string[] = [];
  const consoleErrorStub = stub(console, "error", (...args: unknown[]) => {
    errorLogs.push(args.map(String).join(" "));
  });

  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/debug_logs") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse({ message: "DB error" }, { status: 500 }),
    },
  ]);

  try {
    await withEnv(
      {
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "ai-embed",
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        OPENAI_API_KEY: "openai-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(makeRequest({}));
            assertEquals(response.status, 500);
          });
        });
      },
    );

    // Structured log: console.error is called as log("[ai-embed]", message, metadata)
    // Verify prefix format AND that a non-empty message follows
    const structuredErrorLog = errorLogs.find((entry) => entry.startsWith("[ai-embed] "));
    assertEquals(typeof structuredErrorLog, "string", "Expected structured error log with [ai-embed] prefix");
    assertEquals(structuredErrorLog!.length > "[ai-embed] ".length, true, "Log message must be non-empty");
  } finally {
    consoleErrorStub.restore();
    stubs.forEach((s) => s.restore());
  }
  },
});
