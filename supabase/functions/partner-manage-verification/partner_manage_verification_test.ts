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
const TEST_VERIFICATION_ID = "ver-001";

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
          ? { permissions: ["PARTNER_EDIT", "PARTY_MANAGE", "MEMBER_MANAGE"] }
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

// Insert route for create action
function insertRoute(id = TEST_VERIFICATION_ID): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verifications") && req.method === "POST",
    handler: () => jsonResponse({ id }),
  };
}

function insertErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verifications") && req.method === "POST",
    handler: () => jsonResponse({ message: "insert error" }, { status: 500 }),
  };
}

// Select route for update action (fetch verification)
function selectVerificationRoute(
  partnerId = TEST_PARTNER_ID,
): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verifications") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () =>
      jsonResponse({ id: TEST_VERIFICATION_ID, partner_id: partnerId }),
  };
}

function selectVerificationNotFoundRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verifications") &&
      req.url.includes("select=") &&
      req.method === "GET",
    handler: () => jsonResponse(null),
  };
}

// Update (PATCH) route
function updateRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verifications") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

function updateErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/verifications") && req.method === "PATCH",
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
          body: JSON.stringify({ action: "create" }),
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

// ─── CREATE: success ───
Deno.test({
  name: "create: inserts verification and returns id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      insertRoute("new-ver-id"),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            category: "academic",
            internal_name: "university_check",
            display_name: "대학교 재학 인증",
            description: "재학증명서 또는 학생증 사진",
            icon_key: "school",
            form_schema: [{ type: "file", label: "증명서 업로드" }],
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.id, "new-ver-id");
      });
    });
  },
});

// ─── CREATE: partner_id server-injected — verify POST body ───
Deno.test({
  name: "create: sends partner_id in insert payload",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let insertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "POST",
        handler: async (req) => {
          insertBody = await req.clone().text();
          return jsonResponse({ id: "new-ver-id" });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            category: "etc",
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(insertBody!);
        assertEquals(parsed.partner_id, TEST_PARTNER_ID);
        assertEquals(parsed.category, "etc");
        assertEquals(parsed.internal_name, "test");
      });
    });
  },
});

// ─── CREATE: missing partner_id → 400 ───
Deno.test({
  name: "create: returns 400 for missing partner_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            category: "etc",
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing partner_id");
      });
    });
  },
});

// ─── CREATE: missing required fields → 400 ───
Deno.test({
  name: "create: returns 400 for missing category",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing or invalid category");
      });
    });
  },
});

Deno.test({
  name: "create: returns 400 for invalid category",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            category: "identity",
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing or invalid category");
      });
    });
  },
});

// ─── CREATE: 403 no permission ───
Deno.test({
  name: "create: returns 403 when user lacks PARTY_MANAGE permission",
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
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            category: "etc",
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── CREATE: 500 permission DB error ───
Deno.test({
  name: "create: returns 500 when permission query fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            category: "etc",
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 500);
        const body = await readJson(res);
        assertEquals(body.error, "Failed to verify partner permissions");
      });
    });
  },
});

// ─── CREATE: 500 insert error ───
Deno.test({
  name: "create: returns 500 when insert fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      insertErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "create",
            partner_id: TEST_PARTNER_ID,
            category: "etc",
            internal_name: "test",
            display_name: "테스트",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

// ─── UPDATE: display_name ───
Deno.test({
  name: "update: updates display_name successfully",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            verification_id: TEST_VERIFICATION_ID,
            display_name: "대학교 재학/졸업 인증",
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── UPDATE: is_active=false (soft delete) ───
Deno.test({
  name: "update: is_active=false soft deletes",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "PATCH",
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
            verification_id: TEST_VERIFICATION_ID,
            is_active: false,
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.is_active, false);
      });
    });
  },
});

// ─── UPDATE: is_active=true (restore) ───
Deno.test({
  name: "update: is_active=true restores",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "PATCH",
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
            verification_id: TEST_VERIFICATION_ID,
            is_active: true,
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.is_active, true);
      });
    });
  },
});

// ─── UPDATE: partial — only sent fields updated ───
Deno.test({
  name: "update: partial update only sends provided fields",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "PATCH",
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
            verification_id: TEST_VERIFICATION_ID,
            description: "Updated description only",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(patchBody!);
        assertEquals(parsed.description, "Updated description only");
        // Should not contain other fields
        assertEquals(Object.keys(parsed).length, 1);
      });
    });
  },
});

// ─── UPDATE: other partner's verification → 403 ───
Deno.test({
  name: "update: returns 403 for other partner's verification",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute("other-partner-id"),
      permRoute(false),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            verification_id: TEST_VERIFICATION_ID,
            display_name: "Hacked name",
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── UPDATE: partner_id change attempt ignored ───
Deno.test({
  name: "update: partner_id in body is ignored (not in update fields)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let patchBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/verifications") && req.method === "PATCH",
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
            verification_id: TEST_VERIFICATION_ID,
            partner_id: "evil-partner-id",
            display_name: "Valid update",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(patchBody!);
        // partner_id should NOT be in the update payload
        assertEquals(parsed.partner_id, undefined);
        assertEquals(parsed.display_name, "Valid update");
      });
    });
  },
});

// ─── UPDATE: missing verification_id → 400 ───
Deno.test({
  name: "update: returns 400 for missing verification_id",
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
            display_name: "Updated",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing verification_id");
      });
    });
  },
});

// ─── UPDATE: verification not found → 404 ───
Deno.test({
  name: "update: returns 404 when verification not found",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationNotFoundRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            verification_id: "nonexistent",
            display_name: "Updated",
          }),
        );
        assertEquals(res.status, 404);
        const body = await readJson(res);
        assertEquals(body.error, "Verification not found");
      });
    });
  },
});

// ─── UPDATE: no fields to update → 400 ───
Deno.test({
  name: "update: returns 400 when no valid fields provided",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            verification_id: TEST_VERIFICATION_ID,
            // Only non-whitelisted fields
            partner_id: "evil-id",
            random_field: "ignored",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "No fields to update");
      });
    });
  },
});

// ─── UPDATE: 500 update error ───
Deno.test({
  name: "update: returns 500 when update fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      selectVerificationRoute(),
      permRoute(),
      updateErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update",
            verification_id: TEST_VERIFICATION_ID,
            display_name: "Updated",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});
