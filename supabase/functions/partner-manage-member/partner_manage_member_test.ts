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
const TEST_TARGET_USER_ID = "user-target-member";
const TEST_PARTNER_ID = "partner-001";

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
    matcher: (req) => req.url.includes("partner_member_permissions") && req.url.includes("select"),
    handler: () =>
      jsonResponse(
        hasPermission
          ? { role: "owner", permissions: ["PARTNER_EDIT", "MEMBER_MANAGE"] }
          : null,
      ),
  };
}

function permErrorRoute(): FetchRoute {
  return {
    matcher: (req) => req.url.includes("partner_member_permissions") && req.url.includes("select"),
    handler: () => jsonResponse({ message: "db error" }, { status: 500 }),
  };
}

function updateRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_member_permissions") && req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

function updateErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_member_permissions") && req.method === "PATCH",
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
          body: JSON.stringify({ action: "update_role" }),
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

// ─── update_role: success ───
Deno.test({
  name: "update_role: updates role successfully",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── update_role: verify payload sent to DB ───
Deno.test({
  name: "update_role: sends correct payload to DB",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let updateBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_member_permissions") && req.method === "PATCH",
        handler: async (req) => {
          updateBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(updateBody!);
        assertEquals(parsed.role, "manager");
        assertEquals(Object.keys(parsed).length, 1);
      });
    });
  },
});

// ─── update_role: missing partner_id → 400 ───
Deno.test({
  name: "update_role: returns 400 for missing partner_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            user_id: TEST_TARGET_USER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing partner_id");
      });
    });
  },
});

// ─── update_role: missing user_id → 400 ───
Deno.test({
  name: "update_role: returns 400 for missing user_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing user_id");
      });
    });
  },
});

// ─── update_role: missing role → 400 ───
Deno.test({
  name: "update_role: returns 400 for missing role",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing role");
      });
    });
  },
});

// ─── update_role: invalid role → 400 ───
Deno.test({
  name: "update_role: returns 400 for invalid role",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            role: "superadmin",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Invalid role: superadmin");
      });
    });
  },
});

// ─── update_role: self role change → 400 ───
Deno.test({
  name: "update_role: returns 400 when changing own role",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_USER_ID,
            role: "staff",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Cannot change own role");
      });
    });
  },
});

// ─── update_role: 403 no permission ───
Deno.test({
  name: "update_role: returns 403 when user lacks MEMBER_MANAGE permission",
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
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── update_role: 500 permission DB error ───
Deno.test({
  name: "update_role: returns 500 when permission query fails",
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
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 500);
        const body = await readJson(res);
        assertEquals(body.error, "Failed to verify partner permissions");
      });
    });
  },
});

// ─── update_role: 500 update error ───
Deno.test({
  name: "update_role: returns 500 when update fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      updateErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_role",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            role: "manager",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

// ─── update_permissions: success ───
Deno.test({
  name: "update_permissions: updates permissions successfully",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      updateRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            permissions: ["PARTY_MANAGE", "COMMENT_MANAGE"],
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── update_permissions: verify payload sent to DB ───
Deno.test({
  name: "update_permissions: sends correct payload to DB",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let updateBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_member_permissions") && req.method === "PATCH",
        handler: async (req) => {
          updateBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            permissions: ["PARTY_MANAGE", "COMMENT_MANAGE"],
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(updateBody!);
        assertEquals(parsed.permissions, ["PARTY_MANAGE", "COMMENT_MANAGE"]);
        assertEquals(Object.keys(parsed).length, 1);
      });
    });
  },
});

// ─── update_permissions: missing partner_id → 400 ───
Deno.test({
  name: "update_permissions: returns 400 for missing partner_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            user_id: TEST_TARGET_USER_ID,
            permissions: ["PARTY_MANAGE"],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing partner_id");
      });
    });
  },
});

// ─── update_permissions: missing user_id → 400 ───
Deno.test({
  name: "update_permissions: returns 400 for missing user_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            permissions: ["PARTY_MANAGE"],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing user_id");
      });
    });
  },
});

// ─── update_permissions: missing permissions → 400 ───
Deno.test({
  name: "update_permissions: returns 400 for missing permissions",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing permissions");
      });
    });
  },
});

// ─── update_permissions: invalid permission → 400 ───
Deno.test({
  name: "update_permissions: returns 400 for invalid permission",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            permissions: ["PARTY_MANAGE", "HACK_SYSTEM"],
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Invalid permission: HACK_SYSTEM");
      });
    });
  },
});

// ─── update_permissions: 403 no permission ───
Deno.test({
  name: "update_permissions: returns 403 when user lacks MEMBER_MANAGE permission",
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
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            permissions: ["PARTY_MANAGE"],
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── update_permissions: 500 update error ───
Deno.test({
  name: "update_permissions: returns 500 when update fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      updateErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "update_permissions",
            partner_id: TEST_PARTNER_ID,
            user_id: TEST_TARGET_USER_ID,
            permissions: ["PARTY_MANAGE"],
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});
