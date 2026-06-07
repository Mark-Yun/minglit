import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  type FetchRoute,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
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
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "partner-manage-event",
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
          ? {
            partner_id: TEST_PARTNER_ID,
            permissions: ["PARTNER_EDIT", "PARTY_MANAGE"],
          }
          : null,
      ),
  };
}

function permNoEventManageRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse({
        partner_id: TEST_PARTNER_ID,
        permissions: ["PARTNER_EDIT"],
      }),
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
      jsonResponse({
        id: TEST_PARTY_ID,
        partner_id: partnerId,
        location_id: locationId,
      }),
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
  overrides: { startTime?: string; currentParticipants?: number } = {},
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
        start_time: overrides.startTime ?? FUTURE_START,
        end_time: FUTURE_END,
        current_participants: overrides.currentParticipants ?? 0,
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

function insertEventChangeLogRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/event_change_logs") && req.method === "POST",
    handler: () => jsonResponse({ id: "change-log-001" }),
  };
}

function selectLocationRoute(partnerId = TEST_PARTNER_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/locations") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse({ id: "loc-001", partner_id: partnerId }),
  };
}

function selectLocationNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/locations") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

function selectLocationErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/locations") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse({ message: "load error" }, { status: 500 }),
  };
}

// Entry group templates/groups routes
function selectEntryGroupTemplatesRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") &&
      req.method === "GET",
    handler: () =>
      jsonResponse([
        {
          label: "남성",
          gender: "male",
          birth_year_min: 2000,
          birth_year_max: 2005,
          required_verification_ids: [],
        },
        {
          label: "여성",
          gender: "female",
          birth_year_min: 2000,
          birth_year_max: 2005,
          required_verification_ids: [],
        },
      ]),
  };
}

function selectEntryGroupTemplatesEmptyRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") &&
      req.method === "GET",
    handler: () => jsonResponse([]),
  };
}

function selectEntryGroupTemplatesErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") &&
      req.method === "GET",
    handler: () => jsonResponse({ message: "load error" }, { status: 500 }),
  };
}

function insertEntryGroupsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_groups") && req.method === "POST",
    handler: async (req) => {
      const rows = await req.json();
      const length = Array.isArray(rows) ? rows.length : 1;
      return jsonResponse(
        Array.from({ length }, (_, i) => ({
          id: `eg-${String(i + 1).padStart(3, "0")}`,
        })),
      );
    },
  };
}

function insertEntryGroupsErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_groups") && req.method === "POST",
    handler: () => jsonResponse({ message: "insert error" }, { status: 500 }),
  };
}

// Ticket template routes
function selectTicketTemplatesRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
    handler: () =>
      jsonResponse([
        {
          id: TEST_TEMPLATE_ID_1,
          name: "남성 티켓",
          description: null,
          price: 30000,
          target_entry_group_ids: [],
          required_verification_ids: [],
        },
        {
          id: TEST_TEMPLATE_ID_2,
          name: "여성 티켓",
          description: null,
          price: 20000,
          target_entry_group_ids: [],
          required_verification_ids: [],
        },
      ]),
  };
}

function selectTicketTemplatesEmptyRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
    handler: () => jsonResponse([]),
  };
}

function selectTicketTemplatesErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/ticket_templates") && req.method === "GET",
    handler: () => jsonResponse({ message: "load error" }, { status: 500 }),
  };
}

function insertTicketsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

function insertTicketsErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "POST",
    handler: () => jsonResponse({ message: "insert error" }, { status: 500 }),
  };
}

function insertSingleTicketRoute(id = TEST_TICKET_ID_1): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "POST",
    handler: () => jsonResponse({ id }),
  };
}

function insertSingleTicketErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tickets") && req.method === "POST",
    handler: () => jsonResponse({ message: "insert error" }, { status: 500 }),
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
        {
          id: TEST_TICKET_ID_1,
          sold_count: soldCount1,
          event_id: TEST_EVENT_ID,
        },
        {
          id: TEST_TICKET_ID_2,
          sold_count: soldCount2,
          event_id: TEST_EVENT_ID,
        },
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
  fn: async () => {
    await withEnv(ENV, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const req = new Request("http://localhost", { method: "OPTIONS" });
        const res = await handler(req);
        assertEquals(res.status, 200);
      });
    });
  },
});

Deno.test({
  name: "GET returns 405",
  fn: async () => {
    // minglitEdgeFunction runs auth before handler; authenticated GET reaches handler → 405
    const { fetchMock } = createFetchMock([authRoute()]);
    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const handler = await captureServeHandler(
            new URL("./index.ts", import.meta.url),
          );
          const req = new Request("http://localhost", {
            method: "GET",
            headers: { Authorization: "Bearer test-token" },
          });
          const res = await handler(req);
          assertEquals(res.status, 405);
        });
      });
    });
  },
});

Deno.test({
  name: "Missing auth returns 401",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {});
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, 'Missing or invalid "action" field');
      });
    });
  },
});

Deno.test({
  name: "Unknown action returns 400",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "delete",
        });
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
          event: {
            start_time: FUTURE_START,
            end_time: FUTURE_END,
            max_participants: 20,
          },
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  name: "update: completed event cannot be edited",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("completed"),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: TEST_EVENT_ID,
          event: { start_time: FUTURE_START },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Event is no longer editable");
      });
    });
  },
});

Deno.test({
  name: "update: started scheduled event cannot be edited",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("scheduled", TEST_PARTNER_ID, { startTime: PAST_TIME }),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: TEST_EVENT_ID,
          event: { start_time: FUTURE_START },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Event is no longer editable");
      });
    });
  },
});

Deno.test({
  name: "update: max_participants cannot go below current participants",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute("scheduled", TEST_PARTNER_ID, { currentParticipants: 8 }),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          event_id: TEST_EVENT_ID,
          event: { max_participants: 5 },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "max_participants cannot be lower than current_participants");
      });
    });
  },
});

Deno.test({
  name: "update: max_participants must be a positive integer",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
          event: { max_participants: 0 },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "event.max_participants must be a positive integer");
      });
    });
  },
});

Deno.test({
  name: "update: missing event_id returns 400",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
        assertEquals(
          body.error,
          "Cannot set status to completed — system only",
        );
      });
    });
  },
});

Deno.test({
  name: "update_status: cancelled event cannot change status",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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

Deno.test({
  name: "create: accepts direct entry_groups and tickets",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      insertEventRoute(),
      insertEntryGroupsRoute(),
      insertTicketsRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: {
            start_time: FUTURE_START,
            end_time: FUTURE_END,
            title: "Direct event",
          },
          entry_groups: [
            {
              label: "전체",
              gender: null,
              required_verification_ids: [],
            },
          ],
          tickets: [
            {
              name: "일반 티켓",
              price: 30000,
              quantity: 20,
              target_entry_group_ids: [],
              required_verification_ids: [],
            },
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.event_id, TEST_EVENT_ID);
      });
    });
  },
});

Deno.test({
  name: "create: remaps direct ticket target ids to inserted entry group ids",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      insertEventRoute(),
      insertEntryGroupsRoute(),
      insertTicketsRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: {
            start_time: FUTURE_START,
            end_time: FUTURE_END,
            title: "Direct event",
          },
          entry_groups: [
            {
              source_entry_group_id: "egt_male",
              label: "남성",
              gender: "male",
              required_verification_ids: [],
            },
            {
              source_entry_group_id: "egt_female",
              label: "여성",
              gender: "female",
              required_verification_ids: [],
            },
          ],
          tickets: [
            {
              name: "여성 티켓",
              price: 30000,
              quantity: 20,
              target_entry_group_ids: ["egt_female"],
              required_verification_ids: [],
            },
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
      });
    });

    const entryGroupInsert = calls.find((c) =>
      c.url.includes("/rest/v1/entry_groups") && c.method === "POST"
    );
    const ticketInsert = calls.find((c) =>
      c.url.includes("/rest/v1/tickets") && c.method === "POST"
    );
    const insertedEntryGroups = JSON.parse(entryGroupInsert?.body ?? "[]");
    const insertedTickets = JSON.parse(ticketInsert?.body ?? "[]");
    assertEquals(insertedEntryGroups[1].source_entry_group_id, undefined);
    assertEquals(insertedTickets[0].target_entry_group_ids, ["eg-002"]);
  },
});

Deno.test({
  name:
    "create: rejects direct ticket target ids without matching entry group source",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party_id: TEST_PARTY_ID,
          event: {
            start_time: FUTURE_START,
            end_time: FUTURE_END,
            title: "Direct event",
          },
          entry_groups: [
            {
              label: "전체",
              required_verification_ids: [],
            },
          ],
          tickets: [
            {
              name: "조건 티켓",
              price: 30000,
              quantity: 20,
              target_entry_group_ids: ["egt_missing"],
              required_verification_ids: [],
            },
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(
          body.error,
          "tickets[0].target_entry_group_ids[0] must reference entry_groups[].source_entry_group_id",
        );
      });
    });

    const eventInserts = calls.filter((c) =>
      c.url.includes("/rest/v1/events") && c.method === "POST"
    );
    assertEquals(eventInserts.length, 0);
  },
});

Deno.test({
  name: "create_ticket: inserts a ticket for permitted event",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectEventRoute(),
      permRoute(),
      insertSingleTicketRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create_ticket",
          ticket: {
            event_id: TEST_EVENT_ID,
            name: "추가 티켓",
            price: 10000,
            quantity: 5,
          },
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.ticket_id, TEST_TICKET_ID_1);
      });
    });
  },
});

Deno.test({
  name: "create: rejects invalid direct child inputs before event insert",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
    ]);

    const baseBody = {
      action: "create",
      party_id: TEST_PARTY_ID,
      event: { start_time: FUTURE_START, end_time: FUTURE_END },
    };

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const cases: Array<Record<string, unknown>> = [
          { ...baseBody, entry_groups: "invalid" },
          { ...baseBody, entry_groups: ["invalid"] },
          { ...baseBody, entry_groups: [{ gender: "unknown" }] },
          { ...baseBody, tickets: "invalid" },
          { ...baseBody, tickets: ["invalid"] },
          {
            ...baseBody,
            tickets: [
              { template_id: TEST_TEMPLATE_ID_1, quantity: 1 },
              { name: "직접 티켓", quantity: 1 },
            ],
          },
          {
            ...baseBody,
            tickets: [{ template_id: TEST_TEMPLATE_ID_1, quantity: -1 }],
          },
          { ...baseBody, tickets: [{ quantity: 1 }] },
          { ...baseBody, tickets: [{ name: "티켓", price: -1 }] },
          { ...baseBody, tickets: [{ name: "티켓", quantity: -1 }] },
          {
            ...baseBody,
            event: {
              start_time: FUTURE_START,
              end_time: FUTURE_END,
              location_id: 123,
            },
          },
        ];

        for (const body of cases) {
          const res = await handler(
            authenticatedJsonRequest("http://localhost", body),
          );
          assertEquals(res.status, 400);
        }
      });
    });
  },
});

Deno.test({
  name: "create: handles location and child insert/fetch failures",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const bodyWithLocation = {
      action: "create",
      party_id: TEST_PARTY_ID,
      event: {
        start_time: FUTURE_START,
        end_time: FUTURE_END,
        location_id: "loc-001",
      },
    };

    await withEnv(ENV, async () => {
      let fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        selectLocationErrorRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", bodyWithLocation),
        );
        assertEquals(res.status, 500);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        selectLocationNotFoundRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", bodyWithLocation),
        );
        assertEquals(res.status, 404);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        selectLocationRoute("other-partner"),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", bodyWithLocation),
        );
        assertEquals(res.status, 403);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        insertEventRoute(),
        insertEntryGroupsErrorRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            party_id: TEST_PARTY_ID,
            event: { start_time: FUTURE_START, end_time: FUTURE_END },
            entry_groups: [{ label: "전체" }],
          }),
        );
        assertEquals(res.status, 500);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        insertEventRoute(),
        selectEntryGroupTemplatesErrorRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            party_id: TEST_PARTY_ID,
            event: { start_time: FUTURE_START, end_time: FUTURE_END },
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

Deno.test({
  name: "create: handles ticket template and ticket insert failures",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const baseBody = {
      action: "create",
      party_id: TEST_PARTY_ID,
      event: { start_time: FUTURE_START, end_time: FUTURE_END },
      tickets: [{ template_id: TEST_TEMPLATE_ID_1, quantity: 1 }],
    };

    await withEnv(ENV, async () => {
      let fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        insertEventRoute(),
        selectEntryGroupTemplatesEmptyRoute(),
        selectTicketTemplatesErrorRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", baseBody),
        );
        assertEquals(res.status, 500);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        insertEventRoute(),
        selectEntryGroupTemplatesEmptyRoute(),
        selectTicketTemplatesEmptyRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", baseBody),
        );
        assertEquals(res.status, 400);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectPartyRoute(),
        permRoute(),
        insertEventRoute(),
        selectEntryGroupTemplatesEmptyRoute(),
        selectTicketTemplatesRoute(),
        insertTicketsErrorRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", baseBody),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

Deno.test({
  name: "create_ticket: rejects invalid payloads and handles insert failure",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    await withEnv(ENV, async () => {
      let fetchMock = createFetchMock([authRoute()]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        let res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create_ticket",
            ticket: null,
          }),
        );
        assertEquals(res.status, 400);

        res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create_ticket",
            ticket: { name: "티켓", quantity: 1 },
          }),
        );
        assertEquals(res.status, 400);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectEventRoute(),
        permRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create_ticket",
            ticket: { event_id: TEST_EVENT_ID, quantity: 1 },
          }),
        );
        assertEquals(res.status, 400);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectEventRoute(),
        permRoute(),
        insertSingleTicketErrorRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create_ticket",
            ticket: {
              event_id: TEST_EVENT_ID,
              name: "티켓",
              quantity: 1,
            },
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

Deno.test({
  name:
    "update: validates location_id and writes change log when reason is set",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    await withEnv(ENV, async () => {
      let fetchMock = createFetchMock([
        authRoute(),
        selectEventRoute(),
        permRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            event_id: TEST_EVENT_ID,
            event: { location_id: 123 },
          }),
        );
        assertEquals(res.status, 400);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectEventRoute(),
        permRoute(),
        selectLocationNotFoundRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            event_id: TEST_EVENT_ID,
            event: { location_id: "loc-001" },
          }),
        );
        assertEquals(res.status, 404);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectEventRoute(),
        permRoute(),
        selectLocationRoute("other-partner"),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            event_id: TEST_EVENT_ID,
            event: { location_id: "loc-001" },
          }),
        );
        assertEquals(res.status, 403);
      });

      fetchMock = createFetchMock([
        authRoute(),
        selectEventRoute(),
        permRoute(),
        updateEventRoute(),
        insertEventChangeLogRoute(),
      ]).fetchMock;
      await withMockedFetch(fetchMock, async () => {
        const newStart = new Date(Date.now() + 86400000 * 4).toISOString();
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            event_id: TEST_EVENT_ID,
            event: { start_time: newStart },
            reason: "일정 변경",
          }),
        );
        assertEquals(res.status, 200);
      });
    });
  },
});
