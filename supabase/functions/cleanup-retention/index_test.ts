import { assertEquals } from "@std/assert";
import {
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

const AUTH_HEADER = { Authorization: "Bearer test-service-key" };
const POLICIES_URL = "/rest/v1/retention_policies";
const AUDIT_URL = "/rest/v1/retention_policy_audit";

function postRequest(headers: Record<string, string> = AUTH_HEADER): Request {
  return new Request("http://localhost", { method: "POST", headers });
}

Deno.test({
  name: "cleanup-retention - returns 405 for non-POST",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    await withEnv(ENV, async () => {
      const response = await handler(new Request("http://localhost", { method: "GET" }));
      assertEquals(response.status, 405);
    });
  },
});

Deno.test({
  name: "cleanup-retention - returns 401 without auth header",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    await withEnv(ENV, async () => {
      const response = await handler(new Request("http://localhost", { method: "POST" }));
      assertEquals(response.status, 401);
    });
  },
});

Deno.test({
  name: "cleanup-retention - returns 401 with wrong token",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    await withEnv(ENV, async () => {
      const response = await handler(
        new Request("http://localhost", {
          method: "POST",
          headers: { Authorization: "Bearer wrong-key" },
        }),
      );
      assertEquals(response.status, 401);
    });
  },
});

Deno.test({
  name: "cleanup-retention - returns 200 with empty results when no policies",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse([]),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results, []);
        assertEquals(typeof body.total_duration_ms, "number");
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - processes db_table policy via delete_old_rows RPC",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "cron_job_run_details",
              kind: "db_table",
              retention_days: 30,
              target: { schema: "cron", table: "job_run_details", ts_col: "end_time" },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/delete_old_rows",
        handler: () => jsonResponse(42),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results.length, 1);
        assertEquals(body.results[0].id, "cron_job_run_details");
        assertEquals(body.results[0].status, "success");
        assertEquals(body.results[0].rows_deleted, 42);
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - processes pgmq_archive policy via archive RPC",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "pgmq_global_events_archive",
              kind: "pgmq_archive",
              retention_days: 14,
              target: { queue_name: "q_global_events" },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/archive_old_pgmq_messages",
        handler: () => jsonResponse(25),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results[0].id, "pgmq_global_events_archive");
        assertEquals(body.results[0].status, "success");
        assertEquals(body.results[0].rows_deleted, 25);
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - storage_bucket cleanup stops when no stale files",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    // All files are recent (created_at = now)
    const recentFiles = [
      { name: "recent1.png", created_at: new Date().toISOString() },
      { name: "recent2.png", created_at: new Date().toISOString() },
    ];

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "storage_bug_reports",
              kind: "storage_bucket",
              retention_days: 30,
              target: { bucket_id: "bug-report-attachments", path_prefix: "" },
            },
          ]),
      },
      {
        matcher: "/storage/v1/object/list/bug-report-attachments",
        handler: () => jsonResponse(recentFiles),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results[0].id, "storage_bug_reports");
        assertEquals(body.results[0].status, "success");
        assertEquals(body.results[0].rows_deleted, 0);
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - marks policy as error on RPC failure",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "cron_job_run_details",
              kind: "db_table",
              retention_days: 30,
              target: { schema: "cron", table: "job_run_details", ts_col: "end_time" },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/delete_old_rows",
        handler: () => jsonResponse({ message: "permission denied" }, { status: 403 }),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results[0].status, "error");
        assertEquals(typeof body.results[0].error, "string");
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - response shape has required fields",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      { matcher: POLICIES_URL, handler: () => jsonResponse([]) },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        const body = await readJson(response);
        assertEquals(typeof body.total_duration_ms, "number");
        assertEquals(Array.isArray(body.results), true);
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - db_custom_fn calls named RPC and returns rows_deleted",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "event_participants_post_event",
              kind: "db_custom_fn",
              retention_days: 30,
              target: { fn: "admin.anonymize_old_event_participants" },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/anonymize_old_event_participants",
        handler: () => jsonResponse(5),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results[0].id, "event_participants_post_event");
        assertEquals(body.results[0].status, "success");
        assertEquals(body.results[0].rows_deleted, 5);
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - db_custom_fn errors when target.fn is missing",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "bad_custom_fn_policy",
              kind: "db_custom_fn",
              retention_days: 30,
              target: {},
            },
          ]),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results[0].status, "error");
        assertEquals(typeof body.results[0].error, "string");
      });
    });
  },
});

Deno.test({
  name: "cleanup-retention - db_custom_fn marks error on RPC failure",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "event_participants_post_event",
              kind: "db_custom_fn",
              retention_days: 30,
              target: { fn: "admin.anonymize_old_event_participants" },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/anonymize_old_event_participants",
        handler: () => jsonResponse({ message: "permission denied" }, { status: 403 }),
      },
      {
        matcher: POLICIES_URL,
        handler: () => jsonResponse({}),
      },
      {
        matcher: AUDIT_URL,
        handler: () => jsonResponse({}),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const response = await handler(postRequest());
        assertEquals(response.status, 200);
        const body = await readJson(response);
        assertEquals(body.results[0].status, "error");
        assertEquals(typeof body.results[0].error, "string");
      });
    });
  },
});
