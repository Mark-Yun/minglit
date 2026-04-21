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

const POLICIES_URL = "/rest/v1/retention_policies";
const AUDIT_URL = "/rest/v1/retention_policy_audit";

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
        const response = await handler(
          new Request("http://localhost", { method: "POST" }),
        );
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
        // RPC: delete_old_rows
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
        const response = await handler(
          new Request("http://localhost", { method: "POST" }),
        );
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
        const response = await handler(
          new Request("http://localhost", { method: "POST" }),
        );
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
        const response = await handler(
          new Request("http://localhost", { method: "POST" }),
        );
        const body = await readJson(response);
        assertEquals(typeof body.total_duration_ms, "number");
        assertEquals(Array.isArray(body.results), true);
      });
    });
  },
});
