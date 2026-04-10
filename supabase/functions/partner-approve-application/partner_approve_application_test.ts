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
const TEST_PARTNER_ID = "partner-001";
const TEST_APP_ID = "00000000-0000-1000-8000-000000000001";
const TEST_EVENT_ID = "00000000-0000-1000-8000-000000000002";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const BASE_URL = "http://localhost:54321/functions/v1/partner-approve-application";

// ─── Route helpers ───

function authRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: TEST_USER_ID }),
  };
}

function authFailRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
  };
}

function permRoute(role = "owner"): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse({ permissions: ["EVENT_MANAGE"], role }),
  };
}

function permForbiddenRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse({ permissions: ["PARTNER_EDIT"], role: "member" }),
  };
}

// Fix #1219: cover capped and unlimited event capacity in single-approval tests.
function appRoute(
  status = "pending",
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("event_applications") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse({
        id: TEST_APP_ID,
        status,
        event_id: TEST_EVENT_ID,
        events: {
          party_id: "party-001",
          parties: { partner_id: TEST_PARTNER_ID },
        },
      }),
  };
}

function appNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("event_applications") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

// Fix #1219: assert the single-approval RPC result so capacity failures stay fail-closed.
function approveRpcRoute(
  resultStatus = "approved",
  approved = 1,
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rpc/approve_event_application_with_capacity_guard") &&
      req.method === "POST",
    handler: async (req) => {
      const payload = await req.json();
      assertEquals(payload.p_application_id, TEST_APP_ID);
      return jsonResponse([
        {
          result_status: resultStatus,
          approved,
          event_id: TEST_EVENT_ID,
        },
      ]);
    },
  };
}

function eventRoute(
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/events") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse({
        id: TEST_EVENT_ID,
        party_id: "party-001",
        parties: { partner_id: TEST_PARTNER_ID },
      }),
  };
}

// Fix #1219: assert which pending application IDs are approved during bulk processing.
function bulkApproveRpcRoute(
  {
    resultStatus = "approved",
    approvedCount = 2,
    skippedDueToCapacity = 0,
    remainingSlotsBeforeApproval = 2,
  }: {
    resultStatus?: string;
    approvedCount?: number;
    skippedDueToCapacity?: number;
    remainingSlotsBeforeApproval?: number;
  } = {},
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rpc/bulk_approve_event_applications_with_capacity_guard") &&
      req.method === "POST",
    handler: async (req) => {
      const payload = await req.json();
      assertEquals(payload.p_event_id, TEST_EVENT_ID);
      return jsonResponse([
        {
          result_status: resultStatus,
          approved_count: approvedCount,
          skipped_due_to_capacity: skippedDueToCapacity,
          remaining_slots_before_approval: remainingSlotsBeforeApproval,
        },
      ]);
    },
  };
}

// ─── Tests ───

Deno.test({
  name: "OPTIONS returns CORS preflight",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const req = new Request(BASE_URL, { method: "OPTIONS" });
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
    const req = new Request(BASE_URL, { method: "GET" });
    const res = await handler(req);
    assertEquals(res.status, 405);
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
        const req = authenticatedJsonRequest(BASE_URL, {});
        const res = await handler(req);
        assertEquals(res.status, 400);
        const json = await readJson(res);
        assertEquals(json.error, "Missing action");
      });
    });
  },
});

Deno.test({
  name: "approve: single approve success returns 200 with approved:1",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permRoute("owner"),
      approveRpcRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.approved, 1);
      });
    });
  },
});

Deno.test({
  name: "approve: application not found returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: "00000000-0000-1000-8000-999999999999",
        });
        const res = await handler(req);
        assertEquals(res.status, 404);
      });
    });
  },
});

Deno.test({
  name: "approve: already approved status returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("approved"),
      permRoute("owner"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "approve: unauthorized (no auth) returns 401",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authFailRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 401);
      });
    });
  },
});

Deno.test({
  name: "approve: forbidden (insufficient permissions) returns 403",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permForbiddenRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 403);
      });
    });
  },
});

Deno.test({
  name: "approve: owner role bypasses permissions check returns 200",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      {
        matcher: (req) =>
          req.url.includes("partner_member_permissions") && req.method === "GET",
        handler: () => jsonResponse({ permissions: [], role: "owner" }),
      },
      approveRpcRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.approved, 1);
      });
    });
  },
});

Deno.test({
  name: "approve: already processed (compare-and-set returns empty) returns 409",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permRoute("owner"),
      approveRpcRoute("already_processed", 0),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 409);
      });
    });
  },
});

Deno.test({
  name: "approve: returns 409 when event is already full",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permRoute("owner"),
      approveRpcRoute("event_full", 0),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 409);
        const json = await readJson(res);
        assertEquals(json.error, "정원이 초과되었습니다.");
      });
    });
  },
});

Deno.test({
  name: "approve: returns 500 when capacity data is invalid",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permRoute("owner"),
      approveRpcRoute("invalid_capacity", 0),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "approve",
          application_id: TEST_APP_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 500);
        const json = await readJson(res);
        assertEquals(json.error, "Event capacity data is invalid");
      });
    });
  },
});

Deno.test({
  name: "bulk_approve: success returns 200 with approved count",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute("owner"),
      bulkApproveRpcRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "bulk_approve",
          event_id: TEST_EVENT_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.approved, 2);
      });
    });
  },
});

Deno.test({
  name: "bulk_approve: only approves up to remaining capacity",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute("owner"),
      bulkApproveRpcRoute({
        approvedCount: 2,
        skippedDueToCapacity: 1,
        remainingSlotsBeforeApproval: 2,
      }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "bulk_approve",
          event_id: TEST_EVENT_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.approved, 2);
        assertEquals(json.skipped_due_to_capacity, 1);
        assertEquals(json.remaining_slots_before_approval, 2);
      });
    });
  },
});

Deno.test({
  name: "bulk_approve: returns 500 when capacity data is invalid",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute("owner"),
      bulkApproveRpcRoute({
        resultStatus: "invalid_capacity",
        approvedCount: 0,
        skippedDueToCapacity: 0,
        remainingSlotsBeforeApproval: 0,
      }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "bulk_approve",
          event_id: TEST_EVENT_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 500);
        const json = await readJson(res);
        assertEquals(json.error, "Event capacity data is invalid");
      });
    });
  },
});

Deno.test({
  name: "bulk_approve: no pending apps returns 200 with approved:0",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      eventRoute(),
      permRoute("owner"),
      bulkApproveRpcRoute({
        resultStatus: "no_pending",
        approvedCount: 0,
        skippedDueToCapacity: 0,
        remainingSlotsBeforeApproval: 15,
      }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = authenticatedJsonRequest(BASE_URL, {
          action: "bulk_approve",
          event_id: TEST_EVENT_ID,
        });
        const res = await handler(req);
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.approved, 0);
      });
    });
  },
});
