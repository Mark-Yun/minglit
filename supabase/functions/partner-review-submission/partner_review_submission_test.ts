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

const TEST_USER_ID = "user-partner-reviewer";
const TEST_PARTNER_ID = "partner-001";
const TEST_SUBMISSION_ID = "sub-001";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const SNAPSHOT_DATA = [
  {
    submitted_at: "2026-03-20T00:00:00.000Z",
    data: { school: "MIT" },
    result: null,
    reviewed_by: null,
    reviewed_at: null,
    comments: [],
  },
];

function authRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: TEST_USER_ID, email: "reviewer@test.com" }),
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
    matcher: (req) => req.url.includes("partner_member_permissions"),
    handler: () =>
      jsonResponse(
        hasPermission
          ? { permissions: ["VERIFY_REVIEW", "PARTY_MANAGE"] }
          : null,
      ),
  };
}

function permErrorRoute(): FetchRoute {
  return {
    matcher: (req) => req.url.includes("partner_member_permissions"),
    handler: () => jsonResponse({ message: "db error" }, { status: 500 }),
  };
}

function selectSubmissionRoute(
  partnerId = TEST_PARTNER_ID,
  snapshotData = SNAPSHOT_DATA,
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verification_submissions") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse({
        id: TEST_SUBMISSION_ID,
        partner_id: partnerId,
        snapshot_data: snapshotData,
      }),
  };
}

function selectSubmissionNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verification_submissions") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

function updateRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

function updateErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
    handler: () => jsonResponse({ message: "update error" }, { status: 500 }),
  };
}

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

// ─── 401: no auth ───
Deno.test({
  name: "returns 401 without authorization",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authFailRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const req = new Request("http://localhost", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action: "review" }),
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
          authenticatedJsonRequest("http://localhost", {}),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing action");
      });
    });
  },
});

// ─── 400: unknown action ───
Deno.test({
  name: "returns 400 for unknown action",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", { action: "unknown" }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Unknown action: unknown");
      });
    });
  },
});

// ─── REVIEW: approved → status + snapshot_data updated ───
Deno.test({
  name: "review: approved updates status and snapshot_data",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
        handler: async (req) => {
          patchBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "approved",
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);

        // Verify PATCH payload
        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.status, "approved");
        assertEquals(parsed.reviewed_by, TEST_USER_ID);
        assertEquals(typeof parsed.reviewed_at, "string");

        // snapshot_data last entry should have result/reviewed_by/reviewed_at
        const lastEntry = parsed.snapshot_data[0];
        assertEquals(lastEntry.result, "approved");
        assertEquals(lastEntry.reviewed_by, TEST_USER_ID);
        assertEquals(typeof lastEntry.reviewed_at, "string");
      });
    });
  },
});

// ─── REVIEW: rejected + comment ───
Deno.test({
  name: "review: rejected with comment includes comment in snapshot",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
        handler: async (req) => {
          patchBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "rejected",
            comment: "재학증명서가 흐릿합니다",
          }),
        );
        assertEquals(res.status, 200);

        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.status, "rejected");
        const lastEntry = parsed.snapshot_data[0];
        assertEquals(lastEntry.result, "rejected");
        assertEquals(lastEntry.comments.length, 1);
        assertEquals(lastEntry.comments[0].text, "재학증명서가 흐릿합니다");
        assertEquals(lastEntry.comments[0].author, TEST_USER_ID);
      });
    });
  },
});

// ─── REVIEW: reviewed_at, reviewed_by columns updated ───
Deno.test({
  name: "review: updates reviewed_at and reviewed_by columns",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
        handler: async (req) => {
          patchBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "approved",
          }),
        );
        assertEquals(res.status, 200);

        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.reviewed_by, TEST_USER_ID);
        assertEquals(typeof parsed.reviewed_at, "string");
      });
    });
  },
});

// ─── COMMENT: append to snapshot_data ───
Deno.test({
  name: "comment: appends comment to last snapshot entry",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verification_submissions") && req.method === "PATCH",
        handler: async (req) => {
          patchBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "comment",
            submission_id: TEST_SUBMISSION_ID,
            text: "재학증명서가 흐릿합니다. 다시 올려주세요",
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);

        const parsed = JSON.parse(patchBody!);
        // Only snapshot_data should be updated for comment action
        assertEquals(parsed.status, undefined);
        assertEquals(parsed.reviewed_at, undefined);

        const lastEntry = parsed.snapshot_data[0];
        assertEquals(lastEntry.comments.length, 1);
        assertEquals(lastEntry.comments[0].text, "재학증명서가 흐릿합니다. 다시 올려주세요");
        assertEquals(lastEntry.comments[0].author, TEST_USER_ID);
      });
    });
  },
});

// ─── REVIEW: other partner's submission → 403 ───
Deno.test({
  name: "review: returns 403 for other partner's submission",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute("other-partner-id"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "approved",
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── REVIEW: invalid result → 400 ───
Deno.test({
  name: "review: returns 400 for invalid result value",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "maybe",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Invalid result. Must be 'approved' or 'rejected'");
      });
    });
  },
});

// ─── REVIEW: nonexistent submission → 404 ───
Deno.test({
  name: "review: returns 404 for nonexistent submission",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: "nonexistent",
            result: "approved",
          }),
        );
        assertEquals(res.status, 404);
        const body = await readJson(res);
        assertEquals(body.error, "Submission not found");
      });
    });
  },
});

// ─── COMMENT: nonexistent submission → 404 ───
Deno.test({
  name: "comment: returns 404 for nonexistent submission",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "comment",
            submission_id: "nonexistent",
            text: "some comment",
          }),
        );
        assertEquals(res.status, 404);
        const body = await readJson(res);
        assertEquals(body.error, "Submission not found");
      });
    });
  },
});

// ─── REVIEW: missing submission_id → 400 ───
Deno.test({
  name: "review: returns 400 for missing submission_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            result: "approved",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing submission_id");
      });
    });
  },
});

// ─── COMMENT: missing text → 400 ───
Deno.test({
  name: "comment: returns 400 for missing text",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "comment",
            submission_id: TEST_SUBMISSION_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing text");
      });
    });
  },
});

// ─── REVIEW: 500 permission DB error ───
Deno.test({
  name: "review: returns 500 when permission query fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "approved",
          }),
        );
        assertEquals(res.status, 500);
        const body = await readJson(res);
        assertEquals(body.error, "Failed to verify partner permissions");
      });
    });
  },
});

// ─── REVIEW: 500 update error ───
Deno.test({
  name: "review: returns 500 when update fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permRoute(),
      updateErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "review",
            submission_id: TEST_SUBMISSION_ID,
            result: "approved",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

// ─── COMMENT: 500 update error ───
Deno.test({
  name: "comment: returns 500 when update fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectSubmissionRoute(),
      permRoute(),
      updateErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "comment",
            submission_id: TEST_SUBMISSION_ID,
            text: "some comment",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});
