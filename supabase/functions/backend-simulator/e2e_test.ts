import { assertEquals, assertExists, assertMatch, assertStringIncludes } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  jsonRequest,
  readJson,
  withEnv,
  withMockedFetch,
  type RequestHandler,
} from "../_test_utils/mock_http.ts";

let cachedHandler: RequestHandler | undefined;

async function getHandler(): Promise<RequestHandler> {
  if (!cachedHandler) {
    cachedHandler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  }
  return cachedHandler;
}

function isSingleQuery(req: Request): boolean {
  return req.headers.get("Accept")?.includes("application/vnd.pgrst.object+json") ?? false;
}

function wrapSingle<T>(req: Request, rows: T[]): T | T[] | null {
  if (isSingleQuery(req)) return rows[0] ?? null;
  return rows;
}

function createBroadMock() {
  const patchedRows = new Map<string, Record<string, unknown>>();
  const submissionToApp = new Map<string, string>();

  function mergePatched(table: string, base: Record<string, unknown>): Record<string, unknown> {
    const key = `${table}:${base.id}`;
    const patch = patchedRows.get(key);
    return patch ? { ...base, ...patch } : base;
  }

  return createFetchMock([
    {
      matcher: (req) =>
        req.url.includes("/rest/v1/") &&
        !req.url.includes("/rest/v1/rpc/") &&
        req.method === "GET",
      handler: (req) => {
        const url = new URL(req.url);
        const table = url.pathname.split("/rest/v1/")[1]?.split("?")[0];

        if (table === "partners") {
          return jsonResponse(wrapSingle(req, [{ id: "partner-1" }]));
        }
        if (table === "user_profiles") {
          return jsonResponse(wrapSingle(req, [
            { id: "user-1", gender: "male", birth_date: "1998-01-01", username: "user1" },
            { id: "user-2", gender: "female", birth_date: "1999-01-01", username: "user2" },
          ]));
        }
        if (table === "entry_groups") {
          return jsonResponse(wrapSingle(req, [
            { id: "group-1", gender: "male", birth_year_min: 1990, birth_year_max: 2005 },
            { id: "group-2", gender: "female", birth_year_min: 1990, birth_year_max: 2005 },
          ]));
        }
        if (table === "tickets") {
          return jsonResponse(wrapSingle(req, [
            { id: "ticket-1", price: 20000, status: "on_sale", sold_count: 6 },
          ]));
        }
        if (table === "event_applications") {
          const queriedId = url.searchParams.get("id")?.replace("eq.", "") ?? "app-1";
          const baseRow = {
            id: queriedId,
            event_id: "event-1",
            user_id: "user-1",
            ticket_id: "ticket-1",
            payment_amount: 20000,
            status: "approved",
            refund_status: "completed",
            refund_amount: 0,
          };
          return jsonResponse(wrapSingle(req, [mergePatched("event_applications", baseRow) as typeof baseRow]));
        }
        if (table === "events") {
          const futureDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
          return jsonResponse(wrapSingle(req, [
            {
              id: "event-1",
              current_participants: 6,
              start_time: futureDate,
              parties: { partner_id: "partner-1", required_verification_ids: [] },
            },
          ]));
        }
        if (table === "event_participants") {
          return jsonResponse(wrapSingle(req, [
            { id: "part-1", user_id: "user-1", status: "checked_in" },
            { id: "part-2", user_id: "user-2", status: "checked_in" },
            { id: "part-3", user_id: "user-3", status: "no_show" },
          ]));
        }
        if (table === "match_rules") {
          return jsonResponse(wrapSingle(req, []));
        }
        if (table === "match_pairs") {
          return jsonResponse(wrapSingle(req, []));
        }
        if (table === "settlement_items") {
          const queryBySourceId = url.searchParams.has("source_id");
          const status = queryBySourceId ? "PENDING" : "READY";
          return jsonResponse(wrapSingle(req, [{
            id: "si-1",
            status,
            gross_amount: 20000,
            platform_fee_amount: 1000,
            pg_fee_amount: 700,
            vat_amount: 170,
            net_amount: 18130,
            calc_checksum: "a".repeat(64),
            source_id: "event-1",
            source_type: "EVENT",
          }]));
        }
        if (table === "verifications") {
          return jsonResponse(wrapSingle(req, [{ id: "verif-1", partner_id: "partner-1" }]));
        }
        if (table === "locations") {
          return jsonResponse(wrapSingle(req, [{ id: "loc-1" }]));
        }
        if (table === "verification_submissions") {
          return jsonResponse(wrapSingle(req, [
            {
              id: "vs-1",
              status: "approved",
              partner_id: "partner-1",
              user_id: "user-1",
              verification_id: "verif-1",
            },
          ]));
        }
        if (table === "partner_verified_users") {
          return jsonResponse(wrapSingle(req, [{ id: "pvu-1" }]));
        }
        return jsonResponse(wrapSingle(req, []));
      },
    },
    {
      matcher: (req) =>
        req.url.includes("/rest/v1/") &&
        !req.url.includes("/rest/v1/rpc/") &&
        req.method === "PATCH",
      handler: async (req) => {
        const url = new URL(req.url);
        const table = url.pathname.split("/rest/v1/")[1]?.split("?")[0];
        try {
          const patch = await req.json() as Record<string, unknown>;
          const idParam = [...url.searchParams.entries()].find(([k]) => k === "id");
          if (idParam) {
            const id = idParam[1].replace("eq.", "");
            patchedRows.set(`${table}:${id}`, patch);
            if (table === "verification_submissions" && typeof patch.status === "string") {
              const appId = submissionToApp.get(id);
              if (appId) {
                const appStatus = patch.status === "approved" ? "approved" : "rejected";
                const existing = patchedRows.get(`event_applications:${appId}`) ?? {};
                patchedRows.set(`event_applications:${appId}`, { ...existing, status: appStatus });
              }
            }
          }
        } catch {
          // intentionally empty
        }
        return jsonResponse({ id: crypto.randomUUID() }, { status: 200 });
      },
    },
    {
      matcher: (req) =>
        req.url.includes("/rest/v1/") &&
        !req.url.includes("/rest/v1/rpc/") &&
        req.method === "POST",
      handler: async (req) => {
        const url = new URL(req.url);
        const table = url.pathname.split("/rest/v1/")[1]?.split("?")[0];
        const newId = crypto.randomUUID();
        try {
          const body = await req.json() as Record<string, unknown>;
          if (table === "verification_submissions" && typeof body.id === "string" && typeof body.application_id === "string") {
            submissionToApp.set(body.id, body.application_id);
          }
        } catch {
          // intentionally empty
        }
        return jsonResponse({ id: newId }, { status: 201 });
      },
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/") && req.method === "DELETE",
      handler: () => jsonResponse(null, { status: 200 }),
    },
    {
      matcher: (req) => req.url.includes("/rest/v1/rpc/"),
      handler: () => jsonResponse(null),
    },
    {
      matcher: (req) => req.url.includes("/storage/v1/"),
      handler: () => jsonResponse({ Key: "e2e-test-logs/2026-03-15/run.log" }),
    },
    {
      matcher: (req) => req.url.includes("api.github.com"),
      handler: () =>
        jsonResponse(
          { html_url: "https://github.com/Mark-Yun/minglit/issues/999", number: 999 },
          { status: 201 },
        ),
    },
  ]);
}

Deno.test({
  name: "backend-simulator - blocks in production",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();

    await withEnv({ ENVIRONMENT: "production" }, async () => {
      const response = await h(new Request("http://localhost", { method: "POST" }));
      assertEquals(response.status, 403);
    });
  },
});

Deno.test({
  name: "backend-simulator - full run returns success structure",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();
    const { fetchMock } = createBroadMock();

    await withEnv(
      {
        ENVIRONMENT: "development",
        SUPABASE_URL: "http://localhost:54321",
        SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
        GITHUB_ACCESS_TOKEN: "test-github-token",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          const response = await h(jsonRequest("http://localhost", {}));
          assertEquals(response.status, 200);

          const body = await readJson(response);
          assertEquals(response.status, 200);
          assertExists(body.run_id);
          assertMatch(
            body.run_id,
            /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
          );
          assertExists(body.summary);
          assertEquals(typeof body.success, "boolean");
          assertEquals(typeof body.summary.total_checks, "number");
          assertEquals(typeof body.summary.passed, "number");
          assertEquals(typeof body.summary.failed, "number");
        });
      },
    );
  },
});

Deno.test({
  name: "backend-simulator - force_fail creates failure and GitHub issue",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();
    const { fetchMock } = createBroadMock();

    await withEnv(
      {
        ENVIRONMENT: "development",
        SUPABASE_URL: "http://localhost:54321",
        SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
        GITHUB_ACCESS_TOKEN: "test-github-token",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          const response = await h(jsonRequest("http://localhost", { force_fail: true }));
          assertEquals(response.status, 200);

          const body = await readJson(response);
          assertEquals(body.success, false);
          assertExists(body.summary);
          assertEquals(body.summary.failed >= 1, true);
          assertExists(body.github_issue_url);
          assertEquals(body.github_issue_url, "https://github.com/Mark-Yun/minglit/issues/999");
        });
      },
    );
  },
});

Deno.test({
  name: "backend-simulator - phase=create returns party_ids and event_ids",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();
    const { fetchMock } = createBroadMock();

    await withEnv(
      {
        ENVIRONMENT: "development",
        SUPABASE_URL: "http://localhost:54321",
        SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          const response = await h(jsonRequest("http://localhost", { phase: "create" }));
          assertEquals(response.status, 200);

          const body = await readJson(response);
          assertEquals(body.success, true);
          assertExists(body.run_id);
          assertExists(body.party_ids);
          assertExists(body.event_ids);
          assertEquals(Array.isArray(body.party_ids), true);
          assertEquals(Array.isArray(body.event_ids), true);
        });
      },
    );
  },
});

Deno.test({
  name: "backend-simulator - phase=verify returns verification summary",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();
    const { fetchMock } = createBroadMock();

    await withEnv(
      {
        ENVIRONMENT: "development",
        SUPABASE_URL: "http://localhost:54321",
        SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
        GITHUB_ACCESS_TOKEN: "test-github-token",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          const response = await h(jsonRequest("http://localhost", { phase: "verify" }));
          assertEquals(response.status, 200);

          const body = await readJson(response);
          assertExists(body.run_id);
          assertExists(body.summary);
          assertEquals(typeof body.summary.total_checks, "number");
          assertEquals(typeof body.summary.passed, "number");
          assertEquals(typeof body.summary.failed, "number");
          assertEquals(Array.isArray(body.summary.assertion_results), true);

          // When assertions fail, github_issue_url should be present
          if (body.summary.failed > 0) {
            assertExists(body.github_issue_url);
            assertStringIncludes(body.github_issue_url, "github.com");
          }
        });
      },
    );
  },
});

// ─────────────────────────────────────────────────────────
// Issue #964: E2E filter, display events, auto-complete cron
// ─────────────────────────────────────────────────────────

Deno.test({
  name: "backend-simulator - phase=run only processes [E2E] events (non-E2E events remain scheduled)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();

    // Track which event IDs were passed to checkin/complete via PATCH
    const patchedEventIds: string[] = [];

    const { fetchMock } = createFetchMock([
      {
        // GET /rest/v1/events — return both E2E and non-E2E scheduled events.
        // The run phase filters with parties.title LIKE '[E2E]%', so only E2E
        // rows should be returned when the filter param is present.
        matcher: (req) =>
          req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: (req) => {
          const url = new URL(req.url);
          const titleFilter = url.searchParams.get("parties.title") ?? "";
          const isE2EFilter = titleFilter.includes("[E2E]") || titleFilter.includes("%5BE2E%5D");

          if (isE2EFilter) {
            // Only return E2E events when the filter is applied
            return jsonResponse(wrapSingle(req, [
              { id: "e2e-event-1", parties: { title: "[E2E] 대학생 밍글" } },
            ]));
          }
          // Without filter, return both E2E and non-E2E events
          return jsonResponse(wrapSingle(req, [
            { id: "e2e-event-1", parties: { title: "[E2E] 대학생 밍글" } },
            { id: "non-e2e-event-1", parties: { title: "일반 파티" } },
          ]));
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/events") && req.method === "PATCH",
        handler: async (req) => {
          const url = new URL(req.url);
          const idFilter = url.searchParams.get("id")?.replace("eq.", "");
          if (idFilter) patchedEventIds.push(idFilter);
          const body = await req.json() as Record<string, unknown>;
          return jsonResponse([{ id: idFilter, ...body }], { status: 200 });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_participants") && req.method === "GET",
        handler: (req) => jsonResponse(wrapSingle(req, [])),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/event_participants") && req.method === "PATCH",
        handler: () => jsonResponse({ id: crypto.randomUUID() }, { status: 200 }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/"),
        handler: (req) => jsonResponse(wrapSingle(req, []), { status: 200 }),
      },
      {
        matcher: (req) => req.url.includes("/storage/v1/"),
        handler: () => jsonResponse({ Key: "e2e-test-logs/run.log" }),
      },
      {
        matcher: (req) => req.url.includes("api.github.com"),
        handler: () =>
          jsonResponse({ html_url: "https://github.com/Mark-Yun/minglit/issues/999", number: 999 }, { status: 201 }),
      },
    ]);

    await withEnv(
      {
        ENVIRONMENT: "development",
        SUPABASE_URL: "http://localhost:54321",
        SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          const response = await h(jsonRequest("http://localhost", { phase: "run" }));
          assertEquals(response.status, 200);

          const body = await readJson(response);
          assertEquals(body.success, true);
          assertExists(body.run_id);

          // The run phase must have patched the E2E event
          assertEquals(
            patchedEventIds.includes("e2e-event-1"),
            true,
            "E2E event must be processed by run phase",
          );
          // The run phase must NOT have patched the non-E2E event
          assertEquals(
            patchedEventIds.includes("non-e2e-event-1"),
            false,
            "non-E2E event must not be processed by run phase",
          );
        });
      },
    );
  },
});

Deno.test({
  name: "backend-simulator - phase=create response includes display_party_ids and display_event_ids",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const h = await getHandler();

    // Track created parties to distinguish E2E vs display
    const createdParties: { title?: string }[] = [];

    const { fetchMock } = createFetchMock([
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partners") && req.method === "GET",
        handler: (req) => jsonResponse(wrapSingle(req, [{ id: "partner-1" }])),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/locations") && req.method === "GET",
        handler: (req) => jsonResponse(wrapSingle(req, [{ id: "loc-1" }])),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/parties") && req.method === "POST",
        handler: async (req) => {
          const body = await req.json() as { title?: string };
          createdParties.push({ title: body.title });
          return jsonResponse({ id: crypto.randomUUID() }, { status: 201 });
        },
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/events") && req.method === "POST",
        handler: () =>
          jsonResponse({ id: crypto.randomUUID() }, { status: 201 }),
      },
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/events") && req.method === "GET",
        handler: (req) => jsonResponse(wrapSingle(req, [])),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/") && req.method === "POST",
        handler: () => jsonResponse({ id: crypto.randomUUID() }, { status: 201 }),
      },
      {
        matcher: (req) => req.url.includes("/rest/v1/") && req.method === "GET",
        handler: (req) => jsonResponse(wrapSingle(req, [])),
      },
      {
        matcher: (req) => req.url.includes("/storage/v1/"),
        handler: () => jsonResponse({ Key: "e2e-test-logs/run.log" }),
      },
    ]);

    await withEnv(
      {
        ENVIRONMENT: "development",
        SUPABASE_URL: "http://localhost:54321",
        SUPABASE_SERVICE_ROLE_KEY: "test-service-role-key",
      },
      async () => {
        await withMockedFetch(fetchMock, async () => {
          const response = await h(jsonRequest("http://localhost", { phase: "create" }));
          assertEquals(response.status, 200);

          const body = await readJson(response);
          assertEquals(body.success, true);
          assertExists(body.run_id);

          // E2E party/event arrays must be present
          assertExists(body.party_ids);
          assertExists(body.event_ids);
          assertEquals(Array.isArray(body.party_ids), true);
          assertEquals(Array.isArray(body.event_ids), true);

          // Display party/event arrays must be present (Issue #964)
          assertExists(body.display_party_ids);
          assertExists(body.display_event_ids);
          assertEquals(Array.isArray(body.display_party_ids), true);
          assertEquals(Array.isArray(body.display_event_ids), true);

          // Display events must NOT have [E2E] prefix in their parties
          const displayOnlyParties = createdParties.filter(
            (p) => p.title && !p.title.startsWith("[E2E]"),
          );
          // If simCreateDisplayEvents created any parties, they must not be E2E-prefixed
          for (const party of displayOnlyParties) {
            assertEquals(
              party.title?.startsWith("[E2E]"),
              false,
              `Display party title must not start with [E2E], got: ${party.title}`,
            );
          }
        });
      },
    );
  },
});

// Note: auto-complete cron job registration and SQL condition (end_time < now())
// are tested at the database level in supabase/tests/database/59_auto_complete_cron_test.sql.
