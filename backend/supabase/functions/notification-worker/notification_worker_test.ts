import { assertEquals } from "@std/assert";
import { stub } from "@std/testing/mock";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withNoIntervals,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { firebaseServiceAccountJson, mockNotificationMessage } from "../_test_utils/fixtures.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";

async function withFastTimers(fn: () => Promise<void>) {
  const originalNow = Date.now;
  const originalSetTimeout = globalThis.setTimeout;
  let calls = 0;

  Date.now = () => {
    calls += 1;
    return calls <= 2 ? 0 : 60000;
  };
  globalThis.setTimeout = ((callback: () => void) => {
    callback();
    return 0;
  }) as typeof setTimeout;

  try {
    await fn();
  } finally {
    Date.now = originalNow;
    globalThis.setTimeout = originalSetTimeout;
  }
}

Deno.test({
  name: "notification-worker - processes one message and returns done",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
  ];

  const { fetchMock } = createFetchMock([
    {
      matcher: "https://oauth2.googleapis.com/token",
      handler: () => jsonResponse({ access_token: "access-token" }),
    },
    {
      matcher: "https://fcm.googleapis.com/v1/projects/minglit-test/messages:send",
      handler: () => jsonResponse({ name: "projects/minglit-test/messages/1" }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockNotificationMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/fcm_tokens") && req.method === "GET",
      handler: () => jsonResponse([{ token: "fcm-token-1" }]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_notifications") && req.method === "POST",
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
        FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await withFastTimers(async () => {
              const response = await handler(new Request("http://localhost"));
              const payload = await readJson(response);

              assertEquals(response.status, 200);
              assertEquals(payload.status, "done");
            });
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
  name: "notification-worker - FCM invalid token triggers cleanup",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
  ];

  const { fetchMock, calls } = createFetchMock([
    {
      matcher: "https://oauth2.googleapis.com/token",
      handler: () => jsonResponse({ access_token: "access-token" }),
    },
    {
      matcher: "https://fcm.googleapis.com/v1/projects/minglit-test/messages:send",
      handler: () => new Response("UNREGISTERED", { status: 400 }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockNotificationMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/fcm_tokens") && req.method === "GET",
      handler: () => jsonResponse([{ token: "fcm-token-1" }]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/fcm_tokens") && req.method === "DELETE",
      handler: () => jsonResponse({}),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_notifications") && req.method === "POST",
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
        FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await withFastTimers(async () => {
              const response = await handler(new Request("http://localhost"));
              const payload = await readJson(response);

              assertEquals(response.status, 200);
              assertEquals(payload.status, "done");
            });
          });
        });
      },
    );
  } finally {
    const deleteCall = calls.find((call) =>
      call.url.includes("/rest/v1/fcm_tokens") && call.method === "DELETE"
    );
    assertEquals(Boolean(deleteCall), true);
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "notification-worker - missing env returns 500",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: undefined,
      SUPABASE_SERVICE_ROLE_KEY: undefined,
      FIREBASE_SERVICE_ACCOUNT: undefined,
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          await withFastTimers(async () => {
            const response = await handler(new Request("http://localhost"));
            const payload = await readJson(response);

            assertEquals(response.status, 500);
            assertEquals(typeof payload.error, "string");
          });
        });
      });
    },
  );
  },
});
