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
const TEST_EVENT_ID = "event-001";
const TEST_TICKET_ID_1 = "ticket-001";
const TEST_TICKET_ID_2 = "ticket-002";
const TEST_TEMPLATE_ID_1 = "tpl-001";
const TEST_TEMPLATE_ID_2 = "tpl-002";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const FUTURE_START = new Date(Date.now() + 86400000).toISOString(); // +1 day
const FUTURE_END = new Date(Date.now() + 86400000 * 2).toISOString(); // +2 days
const PAST_TIME = new Date(Date.now() - 86400000).toISOString(); // -1 day

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
          ? { partner_id: TEST_PARTNER_ID, permissions: ["PARTNER_EDIT", "PARTY_MANAGE"] }
          : null,
      ),
  };
}

function permNoEventManageRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse({ partner_id: TEST_PARTNER_ID, permissions: ["PARTNER_EDIT"] }),
  };
}

// Party routes
function selectPartyRoute(
  partnerId = TEST_PARTNER_ID,
  locationId: string | null = "loc-001",
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse({ id: TEST_PARTY_ID, partner_id: partnerId, location_id: locationId }),
  };
}

function selectPartyNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

// Event routes
function insertEventRoute(id = TEST_EVENT_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") && req.method === "POST",
    handler: () => jsonResponse({ id }),
  };
}

function selectEventRoute(
  status = "scheduled",
  partnerId = TEST_PARTNER_ID,
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse({
        id: TEST_EVENT_ID,
        status,
        party_id: TEST_PARTY_ID,
        parties: { partner_id: partnerId },
      }),
  };
}

function selectEventNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

function updateEventRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

// Entry group templates/groups routes
function selectEntryGroupTemplatesRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") && req.method === "GET",
    handler: () =>
      jsonResponse([
        { label: "남성", gender: "male", birth_year_min: 2000, birth_year_max: 2005, required_verification_ids: [] },
        { label: "여성", gender: "female", birth_year_min: 2000, birth_year_max: 2005, required_verification_ids: [] },
      ]),
  };
}

function selectEntryGroupTemplatesEmptyRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") && req.method === "GET",
    handler: () => jsonResponse([]),
  };
}

function insertEntryGroupsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_groups") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

// Ticket template routes
function selectTicketTemplatesRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
    handler: () =>
      jsonResponse([
        { id: TEST_TEMPLATE_ID_1, name: "남성 티켓", description: null, price: 30000, target_entry_group_ids: [], required_verification_ids: [] },
        { id: TEST_TEMPLATE_ID_2, name: "여성 티켓", description: null, price: 20000, target_entry_group_ids: [], required_verification_ids: [] },
      ]),
  };
}

function insertTicketsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

// Ticket fetch/update routes for update_tickets
function selectTicketsRoute(soldCount1 = 0, soldCount2 = 0): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse([
        { id: TEST_TICKET_ID_1, sold_count: soldCount1, event_id: TEST_EVENT_ID },
        { id: TEST_TICKET_ID_2, sold_count: soldCount2, event_id: TEST_EVENT_ID },
      ]),
  };
}

function updateTicketRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
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
  name: "Invalid JSON body returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = new Request("http://localhost", {
          method: "POST",
          headers: {
            Authorization: "Bearer test-token",
            "Content-Type": "application/json",
          },
          body: "not json",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "Missing action returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {});
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing action");
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

// ─── create action ───

Deno.test({
  name: "create: event + entry_groups + tickets from templates",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      insertEventRoute(),
      selectEntryGroupTemplatesRoute(),
      insertEntryGroupsRoute(),
      selectTicketTemplatesRoute(),
      insertTicketsRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: { start_time: FUTURE_START, end_time: FUTURE_END, max_participants: 20 },
          tickets: [
            { template_id: TEST_TEMPLATE_ID_1, quantity: 10 },
            { template_id: TEST_TEMPLATE_ID_2, quantity: 10 },
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.event_id, TEST_EVENT_ID);
      });
    });
  },
});

Deno.test({
  name: "create: event with vote_start_at/vote_end_at",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      insertEventRoute(),
      selectEntryGroupTemplatesEmptyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const voteStart = new Date(Date.now() + 86400000).toISOString();
        const voteEnd = new Date(Date.now() + 86400000 * 1.5).toISOString();
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: {
            start_time: FUTURE_START,
            end_time: FUTURE_END,
            vote_start_at: voteStart,
            vote_end_at: voteEnd,
          },
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.event_id, TEST_EVENT_ID);
      });
    });
  },
});

Deno.test({
  name: "create: past start_time returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: { start_time: PAST_TIME, end_time: FUTURE_END },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "start_time must be in the future");
      });
    });
  },
});

Deno.test({
  name: "create: start_time >= end_time returns 400",
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
          event: { start_time: FUTURE_END, end_time: FUTURE_START },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "start_time must be before end_time");
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
          event: { start_time: FUTURE_START, end_time: FUTURE_END },
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
  name: "create: missing event object returns 400",
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
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "create: no partner membership returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: { start_time: FUTURE_START, end_time: FUTURE_END },
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

Deno.test({
  name: "create: no PARTY_MANAGE/EVENT_MANAGE permission returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permNoEventManageRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: { start_time: FUTURE_START, end_time: FUTURE_END },
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── update action ───

Deno.test({
  name: "update: start_time change",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute(),
      permRoute(),
      updateEventRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const newStart = new Date(Date.now() + 86400000 * 3).toISOString();
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: TEST_EVENT_ID,
          event: { start_time: newStart },
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
  name: "update: missing event_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event: { start_time: FUTURE_START },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing event_id");
      });
    });
  },
});

Deno.test({
  name: "update: event not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: "nonexistent",
          event: { start_time: FUTURE_START },
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

Deno.test({
  name: "update: other partner's event returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("scheduled", "other-partner"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: TEST_EVENT_ID,
          event: { start_time: FUTURE_START },
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

Deno.test({
  name: "update: no fields to update returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: TEST_EVENT_ID,
          event: {},
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "No fields to update");
      });
    });
  },
});

// ─── update_status action ───

Deno.test({
  name: "update_status: scheduled → cancelled",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("scheduled"),
      permRoute(),
      updateEventRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          event_id: TEST_EVENT_ID,
          status: "cancelled",
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
  name: "update_status: completed → 400 (system only)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          event_id: TEST_EVENT_ID,
          status: "completed",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Cannot set status to completed — system only");
      });
    });
  },
});

Deno.test({
  name: "update_status: cancelled event cannot change status",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("cancelled"),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          event_id: TEST_EVENT_ID,
          status: "scheduled",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("Cannot change status"), true);
      });
    });
  },
});

Deno.test({
  name: "update_status: missing event_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          status: "cancelled",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "update_status: event not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          event_id: "nonexistent",
          status: "cancelled",
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

Deno.test({
  name: "update_status: other partner's event returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("scheduled", "other-partner"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          event_id: TEST_EVENT_ID,
          status: "cancelled",
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── update_tickets action ───

Deno.test({
  name: "update_tickets: price change",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute(),
      permRoute(),
      selectTicketsRoute(),
      updateTicketRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_tickets",
          event_id: TEST_EVENT_ID,
          tickets: [
            { ticket_id: TEST_TICKET_ID_1, price: 35000 },
          ],
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
  name: "update_tickets: quantity below sold_count returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute(),
      permRoute(),
      selectTicketsRoute(5, 0), // ticket 1 has 5 sold
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_tickets",
          event_id: TEST_EVENT_ID,
          tickets: [
            { ticket_id: TEST_TICKET_ID_1, quantity: 3 }, // 3 < 5 sold
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("sold_count"), true);
      });
    });
  },
});

Deno.test({
  name: "update_tickets: missing event_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_tickets",
          tickets: [{ ticket_id: TEST_TICKET_ID_1, price: 35000 }],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing event_id");
      });
    });
  },
});

Deno.test({
  name: "update_tickets: empty tickets array returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_tickets",
          event_id: TEST_EVENT_ID,
          tickets: [],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "update_tickets: other partner's event returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("scheduled", "other-partner"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_tickets",
          event_id: TEST_EVENT_ID,
          tickets: [{ ticket_id: TEST_TICKET_ID_1, price: 35000 }],
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});
