import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  type FetchRoute,
} from "../_test_utils/mock_http.ts";

const TEST_USER_ID = "user-partner-owner";
const TEST_EVENT_ID = "event-001";
const TEST_PARTY_ID = "party-001";
const TEST_PARTNER_ID = "partner-001";
const GROUP_MALE = "group-male";
const GROUP_FEMALE = "group-female";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

function authRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: TEST_USER_ID, email: "partner@test.com" }),
  };
}

// Event lookup: returns event with party join
function eventRoute(overrides?: { status?: string }): FetchRoute {
  return {
    matcher: (req) => req.url.includes("/rest/v1/events") && req.url.includes("select="),
    handler: () =>
      jsonResponse({
        id: TEST_EVENT_ID,
        status: overrides?.status ?? "scheduled",
        party: { id: TEST_PARTY_ID, partner_id: TEST_PARTNER_ID },
      }),
  };
}

// Permission check: partner_member_permissions
function permRoute(hasPermission = true): FetchRoute {
  return {
    matcher: (req) => req.url.includes("partner_member_permissions"),
    handler: () =>
      jsonResponse(
        hasPermission
          ? { permissions: ["PARTNER_EDIT", "PARTY_MANAGE", "MEMBER_MANAGE"] }
          : null,
      ),
  };
}

// Entry groups validation
function groupsRoute(validIds: string[] = [GROUP_MALE, GROUP_FEMALE]): FetchRoute {
  return {
    matcher: (req) => req.url.includes("entry_groups"),
    handler: () => jsonResponse(validIds.map((id) => ({ id }))),
  };
}

// RPC replace_match_rules
function rpcRoute(success = true): FetchRoute {
  return {
    matcher: (req) => req.url.includes("/rest/v1/rpc/replace_match_rules"),
    handler: () =>
      success
        ? jsonResponse(2)
        : jsonResponse({ message: "rpc error" }, { status: 400 }),
  };
}

// ─── 401: no auth ───
Deno.test({
  name: "returns 401 without authorization",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = new Request("http://localhost", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action: "set_rules", event_id: TEST_EVENT_ID }),
        });
        const res = await handler(req);
        assertEquals(res.status, 401);
      });
    });
  },
});

// ─── 400: missing action ───
Deno.test({
  name: "returns 400 for missing action",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", { event_id: TEST_EVENT_ID }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing action");
      });
    });
  },
});

// ─── 400: missing event_id ───
Deno.test({
  name: "returns 400 for missing event_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", { action: "set_rules" }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing event_id");
      });
    });
  },
});

// ─── 500: event DB error ───
Deno.test({
  name: "returns 500 when event query fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/events"),
        handler: () => jsonResponse({ message: "db error" }, { status: 500 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [],
          }),
        );
        assertEquals(res.status, 500);
        const body = await readJson(res);
        assertEquals(body.error, "Failed to load event");
      });
    });
  },
});

// ─── 403: no partner permission ───
Deno.test({
  name: "returns 403 when user lacks PARTY_MANAGE permission",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [],
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── 500: permission DB error ───
Deno.test({
  name: "returns 500 when permission query fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      {
        matcher: (req) => req.url.includes("partner_member_permissions"),
        handler: () => jsonResponse({ message: "db error" }, { status: 500 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [],
          }),
        );
        assertEquals(res.status, 500);
        const body = await readJson(res);
        assertEquals(body.error, "Failed to verify partner permissions");
      });
    });
  },
});

// ─── 400: completed event ───
Deno.test({
  name: "returns 400 for completed event",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute({ status: "completed" }),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Cannot modify match rules for event with status 'completed'");
      });
    });
  },
});

// ─── set_rules: 2 rules with vote_count (via RPC) ───
Deno.test({
  name: "set_rules: inserts 2 rules with vote_count via RPC",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
      groupsRoute(),
      rpcRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [
              { source_group_id: GROUP_MALE, target_group_id: GROUP_FEMALE, vote_count: 3 },
              { source_group_id: GROUP_FEMALE, target_group_id: GROUP_MALE, vote_count: 2 },
            ],
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.count, 2);
      });
    });
  },
});

// ─── set_rules: empty array clears all rules ───
Deno.test({
  name: "set_rules: empty array clears all rules via RPC",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
      rpcRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [],
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.count, 0);
      });
    });
  },
});

// ─── set_rules: verifies RPC is called with correct payload ───
Deno.test({
  name: "set_rules: sends correct payload to replace_match_rules RPC",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let rpcBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
      groupsRoute(),
      {
        matcher: (req) => req.url.includes("/rest/v1/rpc/replace_match_rules"),
        handler: async (req) => {
          rpcBody = await req.clone().text();
          return jsonResponse(1);
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [
              { source_group_id: GROUP_MALE, target_group_id: GROUP_FEMALE },
            ],
          }),
        );
        assertEquals(res.status, 200);
        // Verify RPC payload includes vote_count default
        const parsed = JSON.parse(rpcBody!);
        assertEquals(parsed.p_event_id, TEST_EVENT_ID);
        assertEquals(Array.isArray(parsed.p_rules), true);
        assertEquals(parsed.p_rules[0].vote_count, 1);
      });
    });
  },
});

// ─── set_rules: invalid group_id → 400 ───
Deno.test({
  name: "set_rules: returns 400 for non-existent group_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
      groupsRoute([GROUP_MALE]), // only male group exists
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [
              { source_group_id: GROUP_MALE, target_group_id: "nonexistent-group", vote_count: 1 },
            ],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("Invalid group IDs"), true);
      });
    });
  },
});

// ─── set_rules: source === target → 400 ───
Deno.test({
  name: "set_rules: returns 400 when source equals target group",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [
              { source_group_id: GROUP_MALE, target_group_id: GROUP_MALE, vote_count: 1 },
            ],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "source_group_id and target_group_id must be different");
      });
    });
  },
});

// ─── set_rules: vote_count = 0 → 400 ───
Deno.test({
  name: "set_rules: returns 400 for vote_count = 0",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "set_rules",
            event_id: TEST_EVENT_ID,
            rules: [
              { source_group_id: GROUP_MALE, target_group_id: GROUP_FEMALE, vote_count: 0 },
            ],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "vote_count must be a positive integer");
      });
    });
  },
});

// ─── clear_rules ───
Deno.test({
  name: "clear_rules: clears all rules via RPC",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
      rpcRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "clear_rules",
            event_id: TEST_EVENT_ID,
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── unknown action → 400 ───
Deno.test({
  name: "returns 400 for unknown action",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "unknown_action",
            event_id: TEST_EVENT_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Unknown action: unknown_action");
      });
    });
  },
});

// ─── CORS preflight ───
Deno.test({
  name: "handles OPTIONS preflight request",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          new Request("http://localhost", { method: "OPTIONS" }),
        );
        assertEquals(res.status, 200);
      });
    });
  },
});
