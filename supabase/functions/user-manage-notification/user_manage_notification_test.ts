import { assertEquals } from "@std/assert";
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

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const AUTH_HEADER = { Authorization: "Bearer valid-token" };

/** Mock getUser returning user-123 */
function mockGetUser() {
  return {
    matcher: (req: Request) => req.url.includes("/auth/v1/user"),
    handler: () => jsonResponse({ id: "user-123" }),
  };
}

Deno.test({
  name: "user-manage-notification - mark_read success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        mockGetUser(),
        {
          matcher: (req) =>
            req.url.includes("/rest/v1/user_notifications") && req.method === "PATCH",
          handler: () => jsonResponse({ id: "notif-1" }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "mark_read", notification_id: "notif-1" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - mark_read not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        mockGetUser(),
        {
          matcher: (req) =>
            req.url.includes("/rest/v1/user_notifications") && req.method === "PATCH",
          handler: () => jsonResponse(null),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "mark_read", notification_id: "notif-999" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 404);
          assertEquals(payload.error, "Notification not found");
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - mark_read missing notification_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([mockGetUser()]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "mark_read" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Missing required parameter: notification_id");
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - mark_all_read success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        mockGetUser(),
        {
          matcher: (req) =>
            req.url.includes("/rest/v1/user_notifications") && req.method === "PATCH",
          handler: () => jsonResponse([{ id: "notif-1" }, { id: "notif-2" }]),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "mark_all_read" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.count, 2);
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - mark_all_read nothing to read returns count 0",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        mockGetUser(),
        {
          matcher: (req) =>
            req.url.includes("/rest/v1/user_notifications") && req.method === "PATCH",
          handler: () => jsonResponse([]),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "mark_all_read" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.count, 0);
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - delete success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        mockGetUser(),
        {
          matcher: (req) =>
            req.url.includes("/rest/v1/user_notifications") && req.method === "DELETE",
          handler: () => jsonResponse({ id: "notif-1" }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "delete", notification_id: "notif-1" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - delete not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([
        mockGetUser(),
        {
          matcher: (req) =>
            req.url.includes("/rest/v1/user_notifications") && req.method === "DELETE",
          handler: () => jsonResponse(null),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "delete", notification_id: "notif-999" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 404);
          assertEquals(payload.error, "Notification not found");
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - no auth returns 401",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest("http://localhost", {
            action: "mark_read",
            notification_id: "notif-1",
          });
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 401);
          assertEquals(typeof payload.error, "string");
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - unknown action returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([mockGetUser()]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = jsonRequest(
            "http://localhost",
            { action: "invalid_action" },
            { headers: AUTH_HEADER },
          );
          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Unknown action: invalid_action");
        });
      });
    });
  },
});

Deno.test({
  name: "user-manage-notification - OPTIONS returns CORS response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(ENV, async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
      const { fetchMock } = createFetchMock([]);

      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const request = new Request("http://localhost", { method: "OPTIONS" });
          const response = await handler(request);

          assertEquals(response.status, 200);
          assertEquals(response.headers.get("Access-Control-Allow-Origin"), "*");
        });
      });
    });
  },
});
