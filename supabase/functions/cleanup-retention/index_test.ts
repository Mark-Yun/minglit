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
  // minglitEdgeFunction wrapper 요구 — env 가드 + fnName 자동감지 escape hatch
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "cleanup-retention",
};

const AUTH_HEADER = { Authorization: "Bearer test-service-key" };
const POLICIES_URL = "/rest/v1/retention_policies";
const AUDIT_URL = "/rest/v1/retention_policy_audit";

function postRequest(headers: Record<string, string> = AUTH_HEADER): Request {
  return new Request("http://localhost", { method: "POST", headers });
}

Deno.test({
  name: "cleanup-retention - returns 405 for non-POST (with auth)",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    await withEnv(ENV, async () => {
      // wrapper auth 통과시킨 후 handler 의 method 가드가 405 반환
      const response = await handler(
        new Request("http://localhost", { method: "GET", headers: AUTH_HEADER }),
      );
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

// Fix #1749: use_absolute_ts=true 경로는 delete_old_rows 대신 delete_expired_rows를 호출해야 함
Deno.test({
  name: "cleanup-retention - db_table with use_absolute_ts dispatches delete_expired_rows RPC",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let deleteExpiredRowsCalled = false;
    let deleteOldRowsCalled = false;

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "archived_records_expired",
              kind: "db_table",
              retention_days: 1825,
              target: {
                schema: "public",
                table: "archived_records",
                ts_col: "archived_at",
                use_absolute_ts: true,
              },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/delete_expired_rows",
        handler: () => {
          deleteExpiredRowsCalled = true;
          return jsonResponse(5);
        },
      },
      {
        matcher: "/rest/v1/rpc/delete_old_rows",
        handler: () => {
          deleteOldRowsCalled = true;
          return jsonResponse(0);
        },
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
        assertEquals(body.results[0].id, "archived_records_expired");
        assertEquals(body.results[0].status, "success");
        assertEquals(body.results[0].rows_deleted, 5);
      });
    });

    assertEquals(deleteExpiredRowsCalled, true, "delete_expired_rows RPC must be called for use_absolute_ts=true");
    assertEquals(deleteOldRowsCalled, false, "delete_old_rows RPC must NOT be called for use_absolute_ts=true");
  },
});

Deno.test({
  name: "cleanup-retention - db_table without use_absolute_ts still dispatches delete_old_rows RPC",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let deleteExpiredRowsCalled = false;
    let deleteOldRowsCalled = false;

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "cron_job_run_details_no_abs",
              kind: "db_table",
              retention_days: 30,
              target: {
                schema: "cron",
                table: "job_run_details",
                ts_col: "end_time",
                use_absolute_ts: false,
              },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/delete_expired_rows",
        handler: () => {
          deleteExpiredRowsCalled = true;
          return jsonResponse(0);
        },
      },
      {
        matcher: "/rest/v1/rpc/delete_old_rows",
        handler: () => {
          deleteOldRowsCalled = true;
          return jsonResponse(3);
        },
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
        assertEquals(body.results[0].status, "success");
        assertEquals(body.results[0].rows_deleted, 3);
      });
    });

    assertEquals(deleteOldRowsCalled, true, "delete_old_rows RPC must be called for use_absolute_ts=false");
    assertEquals(deleteExpiredRowsCalled, false, "delete_expired_rows RPC must NOT be called for use_absolute_ts=false");
  },
});

Deno.test({
  name: "cleanup-retention - skips policy with metadata.skip_cleanup=true without calling any RPC",
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    let rpcCalled = false;

    const { fetchMock } = createFetchMock([
      {
        matcher: POLICIES_URL,
        handler: () =>
          jsonResponse([
            {
              id: "contract_retention",
              kind: "db_table",
              retention_days: 1825,
              target: { schema: "public", table: "archived_records", ts_col: "retention_until", record_type: "contract", use_absolute_ts: true },
              metadata: { skip_cleanup: true },
            },
          ]),
      },
      {
        matcher: "/rest/v1/rpc/",
        handler: () => {
          rpcCalled = true;
          return jsonResponse(0);
        },
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
        assertEquals(body.results[0].id, "contract_retention");
        assertEquals(body.results[0].status, "skipped");
        assertEquals(body.results[0].rows_deleted, 0);
      });
    });

    assertEquals(rpcCalled, false, "No RPC must be called for skip_cleanup=true policy");
  },
});
