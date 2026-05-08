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
import { firebaseServiceAccountJson, mockNotificationMessage, mockMarketingNotificationMessage } from "../_test_utils/fixtures.ts";
import { WorkerUtils } from "../_shared/worker_utils.ts";
import { isNightTimeKST, secondsUntilKST8AM } from "./marketing_guards.ts";

// UTC 13:00 = KST 22:00 (night window for §50 ⑤ test)
const KST_NIGHT_MS = new Date("1970-01-01T13:00:00Z").getTime();

// Like withFastTimers but Date.now returns KST-night values so isNightTimeKST() fires.
async function withNightTimers(fn: () => Promise<void>) {
  const originalNow = Date.now;
  const originalSetTimeout = globalThis.setTimeout;
  let calls = 0;

  Date.now = () => {
    calls += 1;
    return calls <= 2 ? KST_NIGHT_MS : KST_NIGHT_MS + 60000;
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

// UTC 01:00 = KST 10:00 (daytime for §50 ④ prepend test)
const KST_DAY_MS = new Date("1970-01-01T01:00:00Z").getTime();

// Like withFastTimers but Date.now returns KST-daytime values.
async function withDayTimers(fn: () => Promise<void>) {
  const originalNow = Date.now;
  const originalSetTimeout = globalThis.setTimeout;
  let calls = 0;

  Date.now = () => {
    calls += 1;
    return calls <= 2 ? KST_DAY_MS : KST_DAY_MS + 60000;
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await withFastTimers(async () => {
              const response = await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await withFastTimers(async () => {
              const response = await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
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
  name: "notification-worker - unauthorized: no auth returns 401",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
      FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "notification-worker",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          await withFastTimers(async () => {
            const response = await handler(new Request("http://localhost"));
            assertEquals(response.status, 401);
          });
        });
      });
    },
  );
  },
});

Deno.test({
  name: "notification-worker - unauthorized: wrong token returns 401",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: "https://supabase.test",
      SUPABASE_SERVICE_ROLE_KEY: "service-key",
      FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "notification-worker",
    },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          await withFastTimers(async () => {
            const response = await handler(new Request("http://localhost", {
              headers: { "Authorization": "Bearer bad-key" },
            }));
            assertEquals(response.status, 401);
          });
        });
      });
    },
  );
  },
});

Deno.test({
  name: "notification-worker - missing env returns 500",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const { fetchMock } = createFetchMock([]);

  await withEnv(
    {
      SUPABASE_URL: undefined,
      SUPABASE_SERVICE_ROLE_KEY: undefined,
      FIREBASE_SERVICE_ACCOUNT: undefined,
      ENVIRONMENT: "dev",
      MINGLIT_EF_TEST_FN_NAME: "notification-worker",
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

// ── §50 Marketing Notification Guard Tests ──────────────────────────────────

Deno.test({
  name: "isNightTimeKST: KST 22:00 (UTC 13:00) is night",
  fn: () => {
    // UTC 13:00 → KST 22:00 → night
    const utc13 = new Date("2000-01-01T13:00:00Z").getTime();
    assertEquals(isNightTimeKST(utc13), true);
  },
});

Deno.test({
  name: "isNightTimeKST: KST 10:00 (UTC 01:00) is daytime",
  fn: () => {
    // UTC 01:00 → KST 10:00 → daytime
    const utc1 = new Date("2000-01-01T01:00:00Z").getTime();
    assertEquals(isNightTimeKST(utc1), false);
  },
});

Deno.test({
  name: "secondsUntilKST8AM: before 8am returns correct delta",
  fn: () => {
    // UTC 00:00 → KST 09:00 — no, that's daytime
    // UTC 22:00 → KST 07:00 (next day) → before 8am
    const utc22 = new Date("2000-01-01T22:00:00Z").getTime();
    // KST 07:00, 1 hour until KST 08:00
    assertEquals(secondsUntilKST8AM(utc22), 3600);
  },
});

Deno.test({
  name: "notification-worker §50 ①: marketing without consent drops message, no FCM",
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
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockMarketingNotificationMessage]),
    },
    {
      // user_consents: no active marketing consent (empty result)
      matcher: (req) => req.url.includes("/rest/v1/user_consents"),
      handler: () => jsonResponse(null),
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await withFastTimers(async () => {
              const response = await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
              assertEquals(response.status, 200);
            });
          });
        });
      },
    );
  } finally {
    // FCM must NOT have been called
    const fcmCall = calls.find((c) => c.url.includes("fcm.googleapis.com"));
    assertEquals(fcmCall, undefined);
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "notification-worker §50 ①: consent query DB error → pgmq_delete NOT called (message preserved for retry)",
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
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockMarketingNotificationMessage]),
    },
    {
      // Regression(#2040): transient DB error must not cause message to be dropped.
      // Supabase JS returns { data: null, error } on HTTP 5xx; code must throw, not drop.
      matcher: (req) => req.url.includes("/rest/v1/user_consents"),
      handler: () => new Response(
        JSON.stringify({ code: "PGRST001", message: "DB connection error", details: null, hint: null }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      ),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
          });
        });
      },
    );
  } finally {
    // pgmq_delete must NOT be called — message stays in queue for PGMQ VT retry
    const deleteCall = calls.find((c) => c.url.includes("/rest/v1/rpc/pgmq_delete"));
    assertEquals(deleteCall, undefined, "pgmq_delete must not be called on consent query error");
    // FCM must NOT be called
    const fcmCall = calls.find((c) => c.url.includes("fcm.googleapis.com"));
    assertEquals(fcmCall, undefined, "FCM must not be called on consent query error");
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "notification-worker §50 ④: marketing title gets (광고) prepend",
  fn: async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const stubs = [
    stub(WorkerUtils.prototype, "isProcessed", async () => false),
    stub(WorkerUtils.prototype, "markProcessed", async () => {}),
    stub(WorkerUtils.prototype, "moveToDLQ", async () => {}),
    stub(WorkerUtils.prototype, "logTimeLag", () => {}),
  ];

  let insertedTitle: string | undefined;
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockMarketingNotificationMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_consents"),
      handler: () => jsonResponse({ id: "consent-1" }),
    },
    {
      matcher: "https://oauth2.googleapis.com/token",
      handler: () => jsonResponse({ access_token: "access-token" }),
    },
    {
      matcher: "https://fcm.googleapis.com/v1/projects/minglit-test/messages:send",
      handler: () => jsonResponse({ name: "projects/minglit-test/messages/1" }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/fcm_tokens") && req.method === "GET",
      handler: () => jsonResponse([{ token: "fcm-token-1" }]),
    },
    {
      matcher: async (req: Request) => {
        if (req.url.includes("/rest/v1/user_notifications") && req.method === "POST") {
          const body = await req.clone().json();
          insertedTitle = body.title;
          return true;
        }
        return false;
      },
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            // withDayTimers: Date.now returns KST 10:00 → daytime → no night block
            await withDayTimers(async () => {
              await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
            });
          });
        });
      },
    );
  } finally {
    stubs.forEach((s) => s.restore());
  }

  // Title must have (광고) prepended
  assertEquals(insertedTitle?.startsWith("(광고)"), true);
  },
});

Deno.test({
  name: "notification-worker §50 ⑤: marketing at KST night triggers pgmq_set_vt, no FCM",
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
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockMarketingNotificationMessage]),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/user_consents"),
      handler: () => jsonResponse({ id: "consent-1" }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_set_vt"),
      handler: () => jsonResponse({}),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            // withNightTimers: Date.now returns KST 22:00 → isNightTimeKST() = true
            await withNightTimers(async () => {
              const response = await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
              assertEquals(response.status, 200);
            });
          });
        });
      },
    );
  } finally {
    // pgmq_set_vt must have been called
    const setVtCall = calls.find((c) => c.url.includes("/rest/v1/rpc/pgmq_set_vt"));
    assertEquals(Boolean(setVtCall), true);
    // FCM must NOT have been called
    const fcmCall = calls.find((c) => c.url.includes("fcm.googleapis.com"));
    assertEquals(fcmCall, undefined);
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "notification-worker §50 ①: consent DB error does not delete message (retryable)",
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
      matcher: (req) => req.url.includes("/rest/v1/rpc/pgmq_read"),
      handler: () => jsonResponse([mockMarketingNotificationMessage]),
    },
    {
      // Simulate transient DB error on user_consents lookup
      matcher: (req) => req.url.includes("/rest/v1/user_consents"),
      handler: () => new Response(
        JSON.stringify({ message: "connection timeout", code: "08006", details: null, hint: null }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      ),
    },
  ]);

  try {
    await withEnv(
      {
        SUPABASE_URL: "https://supabase.test",
        SUPABASE_SERVICE_ROLE_KEY: "service-key",
        FIREBASE_SERVICE_ACCOUNT: firebaseServiceAccountJson,
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
          });
        });
      },
    );
  } finally {
    // pgmq_delete must NOT be called — message stays in queue for PGMQ VT retry
    const deleteCall = calls.find((c) => c.url.includes("/rest/v1/rpc/pgmq_delete"));
    assertEquals(deleteCall, undefined);
    // FCM must NOT be called
    const fcmCall = calls.find((c) => c.url.includes("fcm.googleapis.com"));
    assertEquals(fcmCall, undefined);
    stubs.forEach((s) => s.restore());
  }
  },
});

Deno.test({
  name: "notification-worker §50: service category bypasses all guards",
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
        ENVIRONMENT: "dev",
        MINGLIT_EF_TEST_FN_NAME: "notification-worker",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          await withNoIntervals(async () => {
            // KST night time — service category must NOT be affected by night guard
            await withNightTimers(async () => {
              const response = await handler(new Request("http://localhost", { headers: { "Authorization": "Bearer service-key" } }));
              assertEquals(response.status, 200);
            });
          });
        });
      },
    );
  } finally {
    // FCM must have been called (service notifications are not blocked)
    const fcmCall = calls.find((c) => c.url.includes("fcm.googleapis.com"));
    assertEquals(Boolean(fcmCall), true);
    // user_consents must NOT have been queried
    const consentCall = calls.find((c) => c.url.includes("/rest/v1/user_consents"));
    assertEquals(consentCall, undefined);
    stubs.forEach((s) => s.restore());
  }
  },
});
