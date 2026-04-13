import { assertEquals } from "@std/assert";
import { stub } from "@std/testing/mock";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";
import { OpenAILLM } from "../_shared/ai/adapters/openai_llm.ts";

const BASE_ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  OPENAI_API_KEY: "openai-key",
};

/** requireServiceRole을 통과하기 위한 인증 헤더 포함 요청 생성 */
function authedRequest(body: unknown): Request {
  return new Request("http://localhost", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${BASE_ENV.SUPABASE_SERVICE_ROLE_KEY}`,
    },
    body: JSON.stringify(body),
  });
}

const mockTagPartyMessage = {
  msg_id: 20,
  read_ct: 0,
  message: {
    id: "trace-tag-1",
    type: "party_created",
    payload: {
      id: "party-1",
      title: "강남 네트워킹 파티",
      description: { ops: [{ insert: "직장인 대상 소셜 모임입니다." }] },
    },
    meta: { occurred_at: 1700000000 },
  },
};

Deno.test({
  name: "ai-extract-tags - processes party_created message and inserts tags",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const stubs = [
      stub(WorkerUtils.prototype, "isProcessed", () => Promise.resolve(false)),
      stub(WorkerUtils.prototype, "markProcessed", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "moveToDLQ", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "logTimeLag", () => {}),
      stub(
        OpenAILLM.prototype,
        "complete",
        () => Promise.resolve('["네트워킹", "직장인", "강남"]'),
      ),
    ];

    const { fetchMock } = createFetchMock([
      {
        // pgmq_read
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
        handler: () => jsonResponse([mockTagPartyMessage]),
      },
      {
        // tags SELECT (not found → null)
        matcher: (req) =>
          req.url.includes("/rest/v1/tags") && req.method === "GET",
        handler: () => jsonResponse(null),
      },
      {
        // tags INSERT
        matcher: (req) =>
          req.url.includes("/rest/v1/tags") && req.method === "POST",
        handler: () => jsonResponse({ id: "tag-uuid-1" }),
      },
      {
        // party_tags INSERT
        matcher: (req) =>
          req.url.includes("/rest/v1/party_tags") && req.method === "POST",
        handler: () => jsonResponse({}),
      },
      {
        // pgmq_delete
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_delete"),
        handler: () => jsonResponse({}),
      },
    ]);

    try {
      await withEnv(BASE_ENV, async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(authedRequest({}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            assertEquals(payload.processed, 1);
          });
        });
      });
    } finally {
      stubs.forEach((s) => s.restore());
    }
  },
});

Deno.test({
  name: "ai-extract-tags - empty queue returns processed 0",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const stubs = [
      stub(WorkerUtils.prototype, "isProcessed", () => Promise.resolve(false)),
      stub(WorkerUtils.prototype, "markProcessed", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "moveToDLQ", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "logTimeLag", () => {}),
      stub(OpenAILLM.prototype, "complete", () => Promise.resolve("[]")),
    ];

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
        handler: () => jsonResponse([]),
      },
    ]);

    try {
      await withEnv(BASE_ENV, async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(authedRequest({}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            assertEquals(payload.processed, 0);
          });
        });
      });
    } finally {
      stubs.forEach((s) => s.restore());
    }
  },
});

Deno.test({
  name: "ai-extract-tags - LLM error is caught and message stays in queue",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const stubs = [
      stub(WorkerUtils.prototype, "isProcessed", () => Promise.resolve(false)),
      stub(WorkerUtils.prototype, "markProcessed", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "moveToDLQ", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "logTimeLag", () => {}),
      stub(OpenAILLM.prototype, "complete", () => {
        throw new Error("OpenAI API failure");
      }),
    ];

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
        handler: () => jsonResponse([mockTagPartyMessage]),
      },
    ]);

    try {
      await withEnv(BASE_ENV, async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(authedRequest({}));
            const payload = await readJson(response);

            // LLM 에러 시 해당 메시지는 processed에서 제외
            assertEquals(response.status, 200);
            assertEquals(payload.processed, 0);
          });
        });
      });
    } finally {
      stubs.forEach((s) => s.restore());
    }
  },
});

Deno.test({
  name: "ai-extract-tags - missing env returns 500",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

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
            // requireServiceRole은 SUPABASE_SERVICE_ROLE_KEY 미설정 시 500 반환
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
  name: "ai-extract-tags - unauthorized request returns 401",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([]);

    await withEnv(BASE_ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          // Authorization 헤더 없는 요청 — requireServiceRole이 401 반환
          const response = await handler(
            jsonRequest("http://localhost", {}),
          );

          assertEquals(response.status, 401);
        });
      });
    });
  },
});

Deno.test({
  name: "ai-extract-tags - tags INSERT 23505 race condition: re-fetches and links party_tags",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    // Fix #1420: When a concurrent worker inserts a tag first (23505 unique_violation),
    // we must re-fetch the existing tag and still proceed to link party_tags.
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const stubs = [
      stub(WorkerUtils.prototype, "isProcessed", () => Promise.resolve(false)),
      stub(WorkerUtils.prototype, "markProcessed", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "moveToDLQ", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "logTimeLag", () => {}),
      stub(
        OpenAILLM.prototype,
        "complete",
        () => Promise.resolve('["네트워킹"]'),
      ),
    ];

    let partyTagsInsertCalled = false;
    let tagsSelectAfterConflictCalled = false;

    // Track request order to distinguish first tags SELECT from re-fetch SELECT
    let tagsGetCount = 0;

    const { fetchMock } = createFetchMock([
      {
        // pgmq_read
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
        handler: () => jsonResponse([mockTagPartyMessage]),
      },
      {
        // tags SELECT — first call returns null (tag not yet seen by this worker)
        // second call (re-fetch after 23505) returns existing tag
        matcher: (req) =>
          req.url.includes("/rest/v1/tags") && req.method === "GET",
        handler: () => {
          tagsGetCount++;
          if (tagsGetCount === 1) {
            // First lookup: tag not found locally
            return jsonResponse(null);
          }
          // Re-fetch after 23505: another worker already inserted it
          tagsSelectAfterConflictCalled = true;
          return jsonResponse({ id: "tag-uuid-race" });
        },
      },
      {
        // tags INSERT — returns 23505 unique_violation (concurrent insert)
        matcher: (req) =>
          req.url.includes("/rest/v1/tags") && req.method === "POST",
        handler: () =>
          new Response(
            JSON.stringify({
              code: "23505",
              message: 'duplicate key value violates unique constraint "tags_name_key"',
            }),
            { status: 409, headers: { "Content-Type": "application/json" } },
          ),
      },
      {
        // party_tags INSERT — must still be called after re-fetch
        matcher: (req) =>
          req.url.includes("/rest/v1/party_tags") && req.method === "POST",
        handler: () => {
          partyTagsInsertCalled = true;
          return jsonResponse({});
        },
      },
      {
        // pgmq_delete
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_delete"),
        handler: () => jsonResponse({}),
      },
    ]);

    try {
      await withEnv(BASE_ENV, async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(authedRequest({}));
            const payload = await readJson(response);

            assertEquals(response.status, 200);
            // Message should be processed successfully despite the race condition
            assertEquals(payload.processed, 1);
            // Re-fetch must have been called after 23505
            assertEquals(tagsSelectAfterConflictCalled, true);
            // party_tags link must have been created using the re-fetched tag
            assertEquals(partyTagsInsertCalled, true);
          });
        });
      });
    } finally {
      stubs.forEach((s) => s.restore());
    }
  },
});

Deno.test({
  name: "ai-extract-tags - non-party_created message is skipped gracefully",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const otherMessage = {
      msg_id: 30,
      read_ct: 0,
      message: {
        id: "trace-other-1",
        type: "user_interaction",
        payload: { user_id: "user-1", party_id: "party-1", action_type: "like" },
        meta: { occurred_at: 1700000000 },
      },
    };

    const stubs = [
      stub(WorkerUtils.prototype, "isProcessed", () => Promise.resolve(false)),
      stub(WorkerUtils.prototype, "markProcessed", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "moveToDLQ", () => Promise.resolve()),
      stub(WorkerUtils.prototype, "logTimeLag", () => {}),
      stub(OpenAILLM.prototype, "complete", () => Promise.resolve("[]")),
    ];

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
        handler: () => jsonResponse([otherMessage]),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_delete"),
        handler: () => jsonResponse({}),
      },
    ]);

    try {
      await withEnv(BASE_ENV, async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            const response = await handler(authedRequest({}));
            const payload = await readJson(response);

            // non-party_created 메시지는 처리 완료로 마킹되어 큐에서 삭제됨
            assertEquals(response.status, 200);
            assertEquals(payload.processed, 1);
          });
        });
      });
    } finally {
      stubs.forEach((s) => s.restore());
    }
  },
});
