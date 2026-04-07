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
const TEST_LOCATION_ID = "loc-001";

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
          ? { partner_id: TEST_PARTNER_ID, permissions: ["PARTNER_EDIT", "PARTY_MANAGE"] }
          : null,
      ),
  };
}

function permNoPartyManageRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse({ partner_id: TEST_PARTNER_ID, permissions: ["PARTNER_EDIT"] }),
  };
}

function permErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () => jsonResponse({ message: "db error" }, { status: 500 }),
  };
}

// Location routes
function selectLocationRoute(partnerId = TEST_PARTNER_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/locations") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse({ id: TEST_LOCATION_ID, partner_id: partnerId }),
  };
}

function insertLocationRoute(id = TEST_LOCATION_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/locations") && req.method === "POST",
    handler: () => jsonResponse({ id }),
  };
}

function updateLocationRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/locations") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

// Party routes
function insertPartyRoute(id = TEST_PARTY_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") && req.method === "POST",
    handler: () => jsonResponse({ id }),
  };
}

function insertPartyErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") && req.method === "POST",
    handler: () => jsonResponse({ message: "insert error" }, { status: 500 }),
  };
}

function selectPartyRoute(
  partnerId = TEST_PARTNER_ID,
  locationId: string | null = TEST_LOCATION_ID,
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

function updatePartyRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

function updatePartyErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/parties") && req.method === "PATCH",
    handler: () => jsonResponse({ message: "update error" }, { status: 500 }),
  };
}

// party_tags routes
function insertPartyTagsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/party_tags") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

function deletePartyTagsRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/party_tags") && req.method === "DELETE",
    handler: () => new Response(null, { status: 200 }),
  };
}

function selectTagsRoute(tagIds: string[]): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/tags") && req.method === "GET",
    handler: () => jsonResponse(tagIds.map((id) => ({ id }))),
  };
}

// Template routes
function insertEntryGroupTemplatesRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/entry_group_templates") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

function insertTicketTemplatesRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/ticket_templates") && req.method === "POST",
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
  name: "create: party + location + templates — full atomic creation",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      insertLocationRoute(),
      insertPartyRoute(),
      insertEntryGroupTemplatesRoute(),
      insertTicketTemplatesRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "대학생 밍글", description: {}, max_participants: 20 },
          location: { name: "강남 라운지", address: "서울 강남구", region_1: "서울", region_2: "강남구" },
          entry_group_templates: [
            { label: "남성", gender: "male", birth_year_min: 2000, birth_year_max: 2005 },
            { label: "여성", gender: "female", birth_year_min: 2000, birth_year_max: 2005 },
          ],
          ticket_templates: [
            { name: "남성 티켓", price: 30000, quantity: 10 },
            { name: "여성 티켓", price: 20000, quantity: 10 },
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.party_id, TEST_PARTY_ID);
      });
    });
  },
});

Deno.test({
  name: "create: with existing location_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      selectLocationRoute(),
      insertPartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "기존 장소 파티" },
          location_id: TEST_LOCATION_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.party_id, TEST_PARTY_ID);
      });
    });
  },
});

Deno.test({
  name: "create: missing party title returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute(), permRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { description: "no title" },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing party title");
      });
    });
  },
});

Deno.test({
  name: "create: missing partner_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          party: { title: "테스트" },
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing partner_id");
      });
    });
  },
});

Deno.test({
  name: "create: missing party object returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
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
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "테스트" },
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

Deno.test({
  name: "create: no PARTY_MANAGE permission returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permNoPartyManageRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "테스트" },
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

Deno.test({
  name: "create: invalid gender in entry_group_templates returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      insertPartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "테스트" },
          entry_group_templates: [{ gender: "invalid" }],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("gender"), true);
      });
    });
  },
});

Deno.test({
  name: "create: negative ticket price returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      insertPartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "테스트" },
          ticket_templates: [{ name: "티켓", price: -1000, quantity: 10 }],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("price"), true);
      });
    });
  },
});

Deno.test({
  name: "create: location belonging to other partner returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      selectLocationRoute("other-partner"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "테스트" },
          location_id: TEST_LOCATION_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
        const body = await readJson(res);
        assertEquals(body.error, "Forbidden: location belongs to another partner");
      });
    });
  },
});

// ─── update action ───

Deno.test({
  name: "update: party title change",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      updatePartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          party: { title: "수정된 제목" },
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
  name: "update: location change",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      updateLocationRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          location: { name: "새 장소" },
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
  name: "update: missing party_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party: { title: "test" },
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
  name: "update: party not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: "nonexistent",
          party: { title: "test" },
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

Deno.test({
  name: "update: other partner's party returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute("other-partner"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          party: { title: "해킹시도" },
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
      selectPartyRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
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
  name: "update_status: active → closed",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      updatePartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          party_id: TEST_PARTY_ID,
          status: "closed",
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
  name: "update_status: invalid status returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          party_id: TEST_PARTY_ID,
          status: "invalid_status",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error.includes("Invalid status"), true);
      });
    });
  },
});

Deno.test({
  name: "update_status: missing party_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          status: "closed",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "update_status: party not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          party_id: "nonexistent",
          status: "closed",
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

Deno.test({
  name: "update_status: other partner's party returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute("other-partner"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update_status",
          party_id: TEST_PARTY_ID,
          status: "closed",
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── create: tag_ids ───

Deno.test({
  name: "create: with tag_ids 3 tags — party_tags inserted",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const tagIds = [
      "00000000-0000-0000-0000-000000000001",
      "00000000-0000-0000-0000-000000000002",
      "00000000-0000-0000-0000-000000000003",
    ];
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      selectTagsRoute(tagIds),
      insertPartyRoute(),
      insertPartyTagsRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "태그 있는 파티" },
          tag_ids: tagIds,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.party_id, TEST_PARTY_ID);
      });
    });
  },
});

Deno.test({
  name: "create: without tag_ids — party created without tags",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // party_tags INSERT route 없이도 성공해야 함
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      insertPartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "태그 없는 파티" },
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
  name: "create: tag_ids with 6 items returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // tag_ids validation now runs before party INSERT — no insertPartyRoute needed
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "태그 초과 파티" },
          tag_ids: [
            "00000000-0000-0000-0000-000000000001",
            "00000000-0000-0000-0000-000000000002",
            "00000000-0000-0000-0000-000000000003",
            "00000000-0000-0000-0000-000000000004",
            "00000000-0000-0000-0000-000000000005",
            "00000000-0000-0000-0000-000000000006",
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "tag_ids must contain at most 5 tags");
      });
    });
  },
});

Deno.test({
  name: "create: tag_ids with nonexistent IDs returns 400 — no party INSERT attempted",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    // Fix #1136: DB existence check on create path — orphaned party prevented
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const requestedIds = [
      "00000000-0000-0000-0000-000000000001",
      "00000000-0000-0000-0000-000000000099", // nonexistent
    ];
    // selectTagsRoute returns only 1 of the 2 IDs — simulates missing tag
    const { fetchMock, calls } = createFetchMock([
      authRoute(),
      permRoute(),
      selectTagsRoute(["00000000-0000-0000-0000-000000000001"]),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "잘못된 태그 파티" },
          tag_ids: requestedIds,
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "One or more tag_ids do not exist");
        // Verify no party INSERT was attempted — orphan prevention confirmed
        const partyInserts = calls.filter(
          (c) => c.url.includes("/rest/v1/parties") && c.method === "POST",
        );
        assertEquals(partyInserts.length, 0);
      });
    });
  },
});

// ─── update: tag_ids ───

Deno.test({
  name: "update: tag_ids provided — existing tags replaced",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // INSERT new tags first, then DELETE old ones not in new set (safe order)
    const tagIds = [
      "00000000-0000-0000-0000-000000000010",
      "00000000-0000-0000-0000-000000000011",
    ];
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      selectTagsRoute(tagIds),
      insertPartyTagsRoute(),
      deletePartyTagsRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          tag_ids: tagIds,
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
  name: "update: tag_ids empty array — all tags removed",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // 빈 배열이면 DELETE만 실행, INSERT 없음
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      deletePartyTagsRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          tag_ids: [],
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
  name: "update: tag_ids undefined — tags not changed",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // tag_ids 없으면 party_tags route 불필요
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
      updatePartyRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          party: { title: "태그 변경 없이 제목만 수정" },
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
  name: "update: tag_ids with 6 items returns 400",
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
          action: "update",
          party_id: TEST_PARTY_ID,
          tag_ids: [
            "00000000-0000-0000-0000-000000000001",
            "00000000-0000-0000-0000-000000000002",
            "00000000-0000-0000-0000-000000000003",
            "00000000-0000-0000-0000-000000000004",
            "00000000-0000-0000-0000-000000000005",
            "00000000-0000-0000-0000-000000000006",
          ],
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "tag_ids must contain at most 5 tags");
      });
    });
  },
});

// Fix #1136: tag_ids validation must run before any DB write (regression tests)

Deno.test({
  name: "create: tag_ids not array returns 400 — no party INSERT attempted",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // No insertPartyRoute — if party INSERT were attempted it would throw "Unhandled fetch"
    const { fetchMock, calls } = createFetchMock([
      authRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "create",
          partner_id: TEST_PARTNER_ID,
          party: { title: "태그 타입 오류" },
          tag_ids: "not-an-array",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "tag_ids must be an array");
        // Verify no party INSERT was attempted
        const partyInserts = calls.filter((c) => c.url.includes("/rest/v1/parties") && c.method === "POST");
        assertEquals(partyInserts.length, 0);
      });
    });
  },
});

Deno.test({
  name: "update: tag_ids not array returns 400 — no party PATCH attempted",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // No updatePartyRoute — if party PATCH were attempted it would throw "Unhandled fetch"
    const { fetchMock, calls } = createFetchMock([
      authRoute(),
      selectPartyRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest("http://localhost", {
          action: "update",
          party_id: TEST_PARTY_ID,
          party: { title: "동시 수정" },
          tag_ids: "not-an-array",
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "tag_ids must be an array");
        // Verify no party PATCH was attempted
        const partyPatches = calls.filter((c) => c.url.includes("/rest/v1/parties") && c.method === "PATCH");
        assertEquals(partyPatches.length, 0);
      });
    });
  },
});
