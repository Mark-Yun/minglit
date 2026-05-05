import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  authenticatedJsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "partner-review-applications",
};

const eventId = "aaaaaaaa-aaaa-1aaa-8aaa-aaaaaaaaaaaa";
const partnerId = "bbbbbbbb-bbbb-1bbb-8bbb-bbbbbbbbbbbb";
const appId1 = "11111111-1111-1111-8111-111111111111";
const appId2 = "22222222-2222-2222-8222-222222222222";

function eventRoute() {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/events") && req.method === "GET",
    handler: () =>
      jsonResponse({
        id: eventId,
        party_id: "pp-1",
        parties: { partner_id: partnerId },
      }),
  };
}

function permissionRoute(hasPermission = true) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/partner_member_permissions") && req.method === "GET",
    handler: () =>
      jsonResponse(
        hasPermission
          ? [{ role: "owner", permissions: ["EVENT_MANAGE"] }]
          : [],
      ),
  };
}

function rpcRoute(result: Record<string, unknown>) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/rpc/batch_review_event_applications") &&
      req.method === "POST",
    handler: () => jsonResponse([result]),
  };
}

Deno.test("returns 405 for non-POST", async () => {
  const { fetchMock } = createFetchMock([]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          new Request("https://supabase.test/partner-review-applications", { method: "GET" }),
        );
        assertEquals(res.status, 405);
      });
    });
  });
});

Deno.test("returns 401 when unauthenticated", async () => {
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.includes("/auth/v1/user"),
      handler: () => new Response(null, { status: 401 }),
    },
  ]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          authenticatedJsonRequest(
            "https://supabase.test/partner-review-applications",
            { event_id: eventId, approvals: [appId1], rejections: [] },
          ),
        );
        assertEquals(res.status, 401);
      });
    });
  });
});

Deno.test("returns 400 when both approvals and rejections empty", async () => {
  const { fetchMock } = createFetchMock([authRoute]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          authenticatedJsonRequest(
            "https://supabase.test/partner-review-applications",
            { event_id: eventId, approvals: [], rejections: [] },
          ),
        );
        assertEquals(res.status, 400);
      });
    });
  });
});

Deno.test("returns 400 when rejection has empty reason", async () => {
  const { fetchMock } = createFetchMock([authRoute]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          authenticatedJsonRequest(
            "https://supabase.test/partner-review-applications",
            {
              event_id: eventId,
              approvals: [],
              rejections: [{ application_id: appId1, reason: "" }],
            },
          ),
        );
        assertEquals(res.status, 400);
      });
    });
  });
});

Deno.test("returns 403 when caller lacks permission", async () => {
  const { fetchMock } = createFetchMock([authRoute, eventRoute(), permissionRoute(false)]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          authenticatedJsonRequest(
            "https://supabase.test/partner-review-applications",
            { event_id: eventId, approvals: [appId1], rejections: [] },
          ),
        );
        assertEquals(res.status, 403);
      });
    });
  });
});

Deno.test("approves and rejects in single call", async () => {
  const { fetchMock } = createFetchMock([
    authRoute,
    eventRoute(),
    permissionRoute(true),
    rpcRoute({
      approved: [appId1],
      rejected: [appId2],
      skipped_due_to_capacity: [],
      skipped_already_processed: [],
      remaining_slots_after: 4,
    }),
  ]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          authenticatedJsonRequest(
            "https://supabase.test/partner-review-applications",
            {
              event_id: eventId,
              approvals: [appId1],
              rejections: [{ application_id: appId2, reason: "조건 미충족" }],
            },
          ),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.approved, [appId1]);
        assertEquals(body.rejected, [appId2]);
        assertEquals(body.skipped_due_to_capacity, []);
        assertEquals(body.remaining_slots_after, 4);
      });
    });
  });
});

Deno.test("returns skipped_due_to_capacity when event full", async () => {
  const { fetchMock } = createFetchMock([
    authRoute,
    eventRoute(),
    permissionRoute(true),
    rpcRoute({
      approved: [],
      rejected: [],
      skipped_due_to_capacity: [appId1, appId2],
      skipped_already_processed: [],
      remaining_slots_after: 0,
    }),
  ]);
  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const handler = await captureServeHandler(
          new URL("./index.ts", import.meta.url),
        );
        const res = await handler(
          authenticatedJsonRequest(
            "https://supabase.test/partner-review-applications",
            { event_id: eventId, approvals: [appId1, appId2], rejections: [] },
          ),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.skipped_due_to_capacity, [appId1, appId2]);
        assertEquals(body.remaining_slots_after, 0);
      });
    });
  });
});
