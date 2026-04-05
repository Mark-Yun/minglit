import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  type FetchRoute,
} from "../_test_utils/mock_http.ts";

const TEST_USER_ID = "user-partner-owner";
const TEST_PARTNER_ID = "partner-001";
const TEST_PARTY_ID = "party-001";
const TEST_RULE_ID = "rule-001";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

// ─── Route helpers ───

function authRoute(userId = TEST_USER_ID): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: userId, email: "partner@test.com" }),
  };
}

function authFailRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
  };
}

function permRoute(hasPermission = true): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse(
        hasPermission
          ? { partner_id: TEST_PARTNER_ID, permissions: ["PARTY_MANAGE"] }
          : null,
      ),
  };
}

function partyRoute(found = true): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") && req.method === "GET",
    handler: () =>
      found
        ? jsonResponse({ id: TEST_PARTY_ID, partner_id: TEST_PARTNER_ID })
        : jsonResponse(null),
  };
}

function insertRuleRoute(id = TEST_RULE_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/recurrence_rules") && req.method === "POST",
    handler: () =>
      jsonResponse({
        id,
        party_id: TEST_PARTY_ID,
        pattern: "weekly",
        days_of_week: [5],
        month_day: null,
        start_time: "19:00",
        end_time: "23:00",
        end_date: null,
        status: "active",
        last_generated_date: null,
        created_at: new Date().toISOString(),
      }),
  };
}

function selectRuleRoute(status = "active"): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/recurrence_rules") && req.method === "GET",
    handler: () =>
      jsonResponse({
        id: TEST_RULE_ID,
        party_id: TEST_PARTY_ID,
        pattern: "weekly",
        days_of_week: [5],
        month_day: null,
        start_time: "19:00",
        end_time: "23:00",
        end_date: null,
        status,
        last_generated_date: null,
        created_at: new Date().toISOString(),
        parties: { partner_id: TEST_PARTNER_ID },
      }),
  };
}

function selectRuleNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/recurrence_rules") && req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

function updateRuleRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/recurrence_rules") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

function entryGroupTemplatesRoute(empty = false): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") && req.method === "GET",
    handler: () =>
      empty
        ? jsonResponse([])
        : jsonResponse([
            {
              id: "egt-001",
              label: "남성",
              gender: "male",
              birth_year_min: 2000,
              birth_year_max: 2005,
              required_verification_ids: [],
            },
          ]),
  };
}

function ticketTemplatesRoute(empty = false): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
    handler: () =>
      empty
        ? jsonResponse([])
        : jsonResponse([
            {
              id: "tt-001",
              name: "남성 티켓",
              description: null,
              price: 30000,
              target_entry_group_ids: [],
              required_verification_ids: [],
            },
          ]),
  };
}

function insertEventRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") && req.method === "POST",
    handler: () => jsonResponse({ id: `event-${crypto.randomUUID()}` }),
  };
}

function insertEntryGroupsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_groups") && req.method === "POST",
    handler: () => jsonResponse([{ id: "eg-001" }]),
  };
}

function insertTicketsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

// ─── Tests ───

Deno.test({
  name: "OPTIONS returns CORS preflight",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const req = new Request("http://localhost", { method: "OPTIONS" });
    const res = await handler(req);
    assertEquals(res.status, 200);
  },
});

Deno.test({
  name: "GET returns 405",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const req = new Request("http://localhost", { method: "GET" });
    const res = await handler(req);
    assertEquals(res.status, 405);
  },
});

Deno.test({
  name: "Missing auth returns 401",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authFailRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = jsonRequest("http://localhost", { action: "create" });
        const res = await handler(req);
        assertEquals(res.status, 401);
      });
    });
  },
});

Deno.test({
  name: "Unknown action returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", { action: "delete" });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Unknown action: delete");
      });
    });
  },
});

// ─── create ───

Deno.test({
  name: "create: happy path returns rule_id and events_created",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      partyRoute(),
      permRoute(),
      insertRuleRoute(),
      entryGroupTemplatesRoute(),
      ticketTemplatesRoute(),
      insertEventRoute(),
      insertEntryGroupsRoute(),
      insertTicketsRoute(),
      updateRuleRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          pattern: "weekly",
          days_of_week: [5],
          month_day: null,
          start_time: "19:00",
          end_time: "23:00",
          end_date: null,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(typeof body.rule_id, "string");
        assertEquals(typeof body.events_created, "number");
      });
    });
  },
});

Deno.test({
  name: "create: missing party_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          pattern: "weekly",
          days_of_week: [5],
          start_time: "19:00",
          end_time: "23:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing party_id");
      });
    });
  },
});

Deno.test({
  name: "create: invalid pattern returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          pattern: "daily",
          days_of_week: [],
          start_time: "19:00",
          end_time: "23:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("Invalid pattern"), true);
      });
    });
  },
});

Deno.test({
  name: "create: missing start_time returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          pattern: "weekly",
          days_of_week: [5],
          end_time: "23:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("start_time"), true);
      });
    });
  },
});

Deno.test({
  name: "create: permission denied returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      partyRoute(),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          pattern: "weekly",
          days_of_week: [5],
          start_time: "19:00",
          end_time: "23:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

Deno.test({
  name: "create: monthly without month_day returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          pattern: "monthly",
          days_of_week: [],
          start_time: "19:00",
          end_time: "23:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("month_day"), true);
      });
    });
  },
});

Deno.test({
  name: "create: party not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      partyRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: "nonexistent",
          pattern: "weekly",
          days_of_week: [5],
          start_time: "19:00",
          end_time: "23:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
        const body = await readJson(res);
        assertEquals(body.error, "Party not found");
      });
    });
  },
});

// ─── update ───

Deno.test({
  name: "update: happy path returns success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("active"),
      permRoute(),
      updateRuleRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          rule_id: TEST_RULE_ID,
          start_time: "20:00",
          end_time: "00:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

Deno.test({
  name: "update: missing rule_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          start_time: "20:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing rule_id");
      });
    });
  },
});

Deno.test({
  name: "update: cancelled rule returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("cancelled"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          rule_id: TEST_RULE_ID,
          start_time: "20:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("cancelled"), true);
      });
    });
  },
});

Deno.test({
  name: "update: rule not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          rule_id: "nonexistent",
          start_time: "20:00",
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

// ─── pause ───

Deno.test({
  name: "pause: happy path returns success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("active"),
      permRoute(),
      updateRuleRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "pause",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

Deno.test({
  name: "pause: already paused rule returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("paused"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "pause",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("paused"), true);
      });
    });
  },
});

Deno.test({
  name: "pause: cancelled rule returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("cancelled"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "pause",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

// ─── resume ───

Deno.test({
  name: "resume: happy path returns success and events_created",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("paused"),
      permRoute(),
      updateRuleRoute(),
      entryGroupTemplatesRoute(true),
      ticketTemplatesRoute(true),
      insertEventRoute(),
      updateRuleRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "resume",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(typeof body.events_created, "number");
      });
    });
  },
});

Deno.test({
  name: "resume: active rule returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("active"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "resume",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("active"), true);
      });
    });
  },
});

// ─── cancel ───

Deno.test({
  name: "cancel: happy path returns success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("active"),
      permRoute(),
      updateRuleRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "cancel",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

Deno.test({
  name: "cancel: already cancelled rule returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("cancelled"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "cancel",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Rule is already cancelled");
      });
    });
  },
});

Deno.test({
  name: "cancel: rule not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "cancel",
          rule_id: "nonexistent",
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

Deno.test({
  name: "cancel: permission denied returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectRuleRoute("active"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "cancel",
          rule_id: TEST_RULE_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});
