import { assertEquals, assertStringIncludes } from "@std/assert";
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
const TEST_APP_ID = "app-001";
const TEST_EVENT_ID = "event-001";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const BASE_URL = "http://localhost:54321/functions/v1/partner-reject-application";

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
    matcher: (req) => req.url.includes("partner_member_permissions"),
    handler: () => jsonResponse({ permissions: ["EVENT_MANAGE"], role }),
  };
}

function permForbiddenRoute(): FetchRoute {
  return {
    matcher: (req) => req.url.includes("partner_member_permissions"),
    handler: () => jsonResponse({ permissions: ["PARTNER_EDIT"], role: "member" }),
  };
}

function appRoute(status = "pending"): FetchRoute {
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

function updateRoute(updated = [{ id: TEST_APP_ID }]): FetchRoute {
  return {
    matcher: (req) => req.url.includes("event_applications") && req.method === "PATCH",
    handler: async (req) => {
      // Verify the PATCH body contains expected rejection fields
      const body = await req.json();
      assertEquals(body.status, "rejected", "PATCH body should set status to 'rejected'");
      assertEquals(typeof body.rejection_reason, "string", "PATCH body should contain rejection_reason");

      // Verify the URL search params contain the expected application ID
      const url = new URL(req.url);
      const idParam = url.searchParams.get("id");
      assertStringIncludes(idParam ?? "", TEST_APP_ID, "PATCH URL should filter by application ID");

      return jsonResponse(updated);
    },
  };
}

// ─── OPTIONS: CORS preflight ───
Deno.test({
  name: "OPTIONS returns CORS",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(new Request(BASE_URL, { method: "OPTIONS" }));
        assertEquals(res.status, 200);
      });
    });
  },
});

// ─── GET: 405 ───
Deno.test({
  name: "GET returns 405",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(new Request(BASE_URL, { method: "GET" }));
        assertEquals(res.status, 405);
      });
    });
  },
});

// ─── 400: missing application_id ───
Deno.test({
  name: "Missing application_id returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, { reason: "Not a good fit" }),
        );
        assertEquals(res.status, 400);
        const json = await readJson(res);
        assertEquals(json.error, "Missing application_id");
      });
    });
  },
});

// ─── 400: missing reason ───
Deno.test({
  name: "Missing reason returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, { application_id: TEST_APP_ID }),
        );
        assertEquals(res.status, 400);
        const json = await readJson(res);
        assertEquals(json.error, "Missing or empty rejection reason");
      });
    });
  },
});

// ─── 200: reject success ───
Deno.test({
  name: "Reject success returns 200 with rejected count",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permRoute(),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: TEST_APP_ID,
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.rejected, 1);
      });
    });
  },
});

// ─── 404: application not found ───
Deno.test({
  name: "Application not found returns 404",
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
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: "nonexistent",
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 404);
        const json = await readJson(res);
        assertEquals(json.error, "Application not found");
      });
    });
  },
});

// ─── 400: already rejected status ───
Deno.test({
  name: "Already rejected status returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("rejected"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: TEST_APP_ID,
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 400);
        const json = await readJson(res);
        assertEquals(json.error, "Cannot reject application with status 'rejected'");
      });
    });
  },
});

// ─── 401: unauthorized ───
Deno.test({
  name: "Unauthorized returns 401",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authFailRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: TEST_APP_ID,
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 401);
      });
    });
  },
});

// ─── 403: forbidden (insufficient permissions) ───
Deno.test({
  name: "Forbidden (insufficient permissions) returns 403",
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
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: TEST_APP_ID,
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 403);
        const json = await readJson(res);
        assertEquals(json.error, "Forbidden: insufficient partner permissions");
      });
    });
  },
});

// ─── 200: owner role bypasses permissions ───
Deno.test({
  name: "Owner role bypasses permissions check",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      {
        matcher: (req) => req.url.includes("partner_member_permissions"),
        handler: () => jsonResponse({ permissions: [], role: "owner" }),
      },
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: TEST_APP_ID,
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 200);
        const json = await readJson(res);
        assertEquals(json.rejected, 1);
      });
    });
  },
});

// ─── 409: already processed (compare-and-set empty) ───
Deno.test({
  name: "Already processed (compare-and-set returns empty) returns 409",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      appRoute("pending"),
      permRoute(),
      updateRoute([]),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest(BASE_URL, {
            application_id: TEST_APP_ID,
            reason: "Not a good fit",
          }),
        );
        assertEquals(res.status, 409);
        const json = await readJson(res);
        assertEquals(json.error, "Application already processed");
      });
    });
  },
});
