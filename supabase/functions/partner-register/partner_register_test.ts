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

const TEST_USER_ID = "user-applicant-001";
const OTHER_USER_ID = "user-other-002";
const TEST_APP_ID = "app-001";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

// Valid complete application data for submit tests
const VALID_APP = {
  id: TEST_APP_ID,
  user_id: TEST_USER_ID,
  status: "draft",
  brand_name: "테스트브랜드",
  biz_type: "individual",
  biz_name: "테스트사업자",
  biz_number: "1234567890",
  representative_name: "홍길동",
  contact_phone: "01012345678",
  contact_email: "test@example.com",
  bank_name: "국민은행",
  account_number: "12345678901234",
  account_holder: "홍길동",
  biz_registration_path: "user-applicant-001/biz_reg_123.pdf",
  bankbook_path: "user-applicant-001/bankbook_123.pdf",
};

function authRoute(userId = TEST_USER_ID): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: userId, email: "test@test.com" }),
  };
}

function authFailRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
  };
}

// SELECT route for fetching application
function selectAppRoute(app: Record<string, unknown> | null = VALID_APP): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_applications") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(app),
  };
}

// INSERT route for save_draft (new)
function insertRoute(id = TEST_APP_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_applications") && req.method === "POST",
    handler: () => jsonResponse({ id }),
  };
}

function insertErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_applications") && req.method === "POST",
    handler: () => jsonResponse({ message: "insert error" }, { status: 500 }),
  };
}

// UPDATE (PATCH) route
function updateRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_applications") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

function updateErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_applications") && req.method === "PATCH",
    handler: () => jsonResponse({ message: "update error" }, { status: 500 }),
  };
}

// Storage list route (for file existence check)
// Returns matching file names based on the search query parameter
function storageListRoute(hasFiles = true): FetchRoute {
  return {
    matcher: (req) => req.url.includes("/storage/v1/object/list/partner-proofs"),
    handler: (req) => {
      if (!hasFiles) return jsonResponse([]);
      // Extract search param from body or URL to return matching filename
      const url = new URL(req.url);
      const prefix = url.pathname.replace("/storage/v1/object/list/partner-proofs/", "");
      // Return a generic file that matches any search
      return jsonResponse([{ name: "biz_reg_123.pdf" }, { name: "bankbook_123.pdf" }]);
    },
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
          body: JSON.stringify({ action: "save_draft" }),
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

// ═══════════════════════════════════════════
// save_draft
// ═══════════════════════════════════════════

// ─── save_draft: new INSERT → returns application_id ───
Deno.test({
  name: "save_draft: new insert returns application_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      insertRoute("new-app-id"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "save_draft",
            data: { brand_name: "테스트", current_step: 1 },
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.application_id, "new-app-id");
      });
    });
  },
});

// ─── save_draft: existing UPDATE ───
Deno.test({
  name: "save_draft: existing update returns application_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "draft" }),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "save_draft",
            application_id: TEST_APP_ID,
            data: { brand_name: "수정된 브랜드", current_step: 2 },
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.application_id, TEST_APP_ID);
      });
    });
  },
});

// ─── save_draft: current_step saved ───
Deno.test({
  name: "save_draft: current_step is persisted",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let insertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_applications") && req.method === "POST",
        handler: async (req) => {
          insertBody = await req.clone().text();
          return jsonResponse({ id: "new-id" });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "save_draft",
            data: { brand_name: "테스트", current_step: 3 },
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(insertBody!);
        assertEquals(parsed.current_step, 3);
        assertEquals(parsed.status, "draft");
      });
    });
  },
});

// ─── save_draft: other user's draft → 403 ───
Deno.test({
  name: "save_draft: returns 403 for other user's draft",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: OTHER_USER_ID, status: "draft" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "save_draft",
            application_id: TEST_APP_ID,
            data: { brand_name: "해킹 시도" },
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── save_draft: pending status → 400 ───
Deno.test({
  name: "save_draft: returns 400 when application is pending",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "pending" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "save_draft",
            application_id: TEST_APP_ID,
            data: { brand_name: "되돌리기 시도" },
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Application cannot be updated in current status");
      });
    });
  },
});

// ─── save_draft: insert error → 500 ───
Deno.test({
  name: "save_draft: returns 500 when insert fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      insertErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "save_draft",
            data: { brand_name: "테스트" },
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

// ═══════════════════════════════════════════
// submit
// ═══════════════════════════════════════════

// ─── submit: draft → pending with all fields valid ───
Deno.test({
  name: "submit: draft → pending with valid data",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    // Use valid biz_number with correct checksum: 1208100083
    const validApp = { ...VALID_APP, biz_number: "1208100088" };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(validApp),
      storageListRoute(true),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── submit: missing required fields → 400 + details ───
Deno.test({
  name: "submit: returns 400 with validation details for missing fields",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const incompleteApp = {
      id: TEST_APP_ID,
      user_id: TEST_USER_ID,
      status: "draft",
      brand_name: "",
      biz_type: null,
      biz_name: null,
      biz_number: null,
      representative_name: null,
      contact_phone: null,
      contact_email: null,
      bank_name: null,
      account_number: null,
      account_holder: null,
      biz_registration_path: null,
      bankbook_path: null,
    };

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(incompleteApp),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "validation_failed");
        assertEquals(Array.isArray(body.details), true);
        // Should have errors for multiple fields
        const fields = body.details.map((d: { field: string }) => d.field);
        assertEquals(fields.includes("brand_name"), true);
        assertEquals(fields.includes("biz_type"), true);
        assertEquals(fields.includes("biz_number"), true);
        assertEquals(fields.includes("contact_phone"), true);
        assertEquals(fields.includes("contact_email"), true);
      });
    });
  },
});

// ─── submit: biz_number format error → 400 ───
Deno.test({
  name: "submit: returns 400 for invalid biz_number format",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const badBizApp = { ...VALID_APP, biz_number: "123" };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(badBizApp),
      storageListRoute(true),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "validation_failed");
        const bizErr = body.details.find((d: { field: string }) => d.field === "biz_number");
        assertEquals(bizErr !== undefined, true);
      });
    });
  },
});

// ─── submit: contact_email format error → 400 ───
Deno.test({
  name: "submit: returns 400 for invalid email format",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const badEmailApp = { ...VALID_APP, biz_number: "1208100088", contact_email: "not-an-email" };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(badEmailApp),
      storageListRoute(true),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "validation_failed");
        const emailErr = body.details.find((d: { field: string }) => d.field === "contact_email");
        assertEquals(emailErr !== undefined, true);
      });
    });
  },
});

// ─── submit: biz_registration_path file not found → 400 ───
Deno.test({
  name: "submit: returns 400 when storage file not found",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const validApp = { ...VALID_APP, biz_number: "1208100088" };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(validApp),
      storageListRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "validation_failed");
      });
    });
  },
});

// ─── submit: pending → re-submit → 400 ───
Deno.test({
  name: "submit: returns 400 when already pending",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const pendingApp = { ...VALID_APP, status: "pending" };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(pendingApp),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Application cannot be submitted in current status");
      });
    });
  },
});

// ─── submit: needs_correction → pending ───
Deno.test({
  name: "submit: needs_correction → pending transition success",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const correctionApp = { ...VALID_APP, status: "needs_correction", biz_number: "1208100088" };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(correctionApp),
      storageListRoute(true),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── submit: missing application_id → 400 ───
Deno.test({
  name: "submit: returns 400 for missing application_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing application_id");
      });
    });
  },
});

// ─── submit: other user's application → 403 ───
Deno.test({
  name: "submit: returns 403 for other user's application",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const otherApp = { ...VALID_APP, user_id: OTHER_USER_ID };
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute(otherApp),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "submit",
            application_id: TEST_APP_ID,
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ═══════════════════════════════════════════
// update
// ═══════════════════════════════════════════

// ─── update: draft → success ───
Deno.test({
  name: "update: draft status allows update",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "draft" }),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            application_id: TEST_APP_ID,
            data: { brand_name: "수정된 브랜드" },
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.application_id, TEST_APP_ID);
      });
    });
  },
});

// ─── update: needs_correction → success ───
Deno.test({
  name: "update: needs_correction status allows update",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "needs_correction" }),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            application_id: TEST_APP_ID,
            data: { brand_name: "보정된 브랜드" },
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── update: pending → 400 ───
Deno.test({
  name: "update: returns 400 when status is pending",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "pending" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            application_id: TEST_APP_ID,
            data: { brand_name: "수정 시도" },
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Application cannot be updated in current status");
      });
    });
  },
});

// ─── update: other user → 403 ───
Deno.test({
  name: "update: returns 403 for other user's application",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: OTHER_USER_ID, status: "draft" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            application_id: TEST_APP_ID,
            data: { brand_name: "해킹" },
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── update: missing application_id → 400 ───
Deno.test({
  name: "update: returns 400 for missing application_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            data: { brand_name: "테스트" },
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing application_id");
      });
    });
  },
});

// ─── update: no valid fields → 400 ───
Deno.test({
  name: "update: returns 400 when no valid fields in data",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "draft" }),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            application_id: TEST_APP_ID,
            data: { status: "approved", user_id: "hacker" },
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "No fields to update");
      });
    });
  },
});

// ─── update: whitelisted fields only — status/user_id ignored ───
Deno.test({
  name: "update: only whitelisted fields are sent to DB",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectAppRoute({ id: TEST_APP_ID, user_id: TEST_USER_ID, status: "draft" }),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_applications") && req.method === "PATCH",
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
            action: "update",
            application_id: TEST_APP_ID,
            data: {
              brand_name: "정상 수정",
              status: "approved",
              user_id: "hacker-id",
              id: "fake-id",
            },
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.brand_name, "정상 수정");
        assertEquals(parsed.status, undefined);
        assertEquals(parsed.user_id, undefined);
        assertEquals(parsed.id, undefined);
      });
    });
  },
});
