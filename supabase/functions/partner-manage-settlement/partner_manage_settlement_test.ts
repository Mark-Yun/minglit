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
          ? { permissions: ["PARTNER_EDIT", "SETTLEMENT_EDIT", "SETTLEMENT_VIEW"] }
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

// Upsert route (POST to partner_settlements)
function upsertRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_settlements") && req.method === "POST",
    handler: () => new Response(null, { status: 200 }),
  };
}

function upsertErrorRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_settlements") && req.method === "POST",
    handler: () => jsonResponse({ message: "upsert error" }, { status: 500 }),
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
          body: JSON.stringify({ action: "upsert_bank_account" }),
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

// ─── UPSERT: success ───
Deno.test({
  name: "upsert_bank_account: upserts bank account successfully",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      upsertRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─── UPSERT: verify payload sent to DB ───
Deno.test({
  name: "upsert_bank_account: sends correct payload to DB",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") && req.method === "POST",
        handler: async (req) => {
          upsertBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(upsertBody!);
        assertEquals(parsed.partner_id, TEST_PARTNER_ID);
        assertEquals(parsed.bank_name, "카카오뱅크");
        assertEquals(parsed.account_holder, "홍길동");
        // account_number is normalized: hyphens stripped
        assertEquals(parsed.account_number, "3333011234567");
      });
    });
  },
});

// ─── UPSERT: extra fields ignored ───
Deno.test({
  name: "upsert_bank_account: ignores non-whitelisted fields",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") && req.method === "POST",
        handler: async (req) => {
          upsertBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
            biz_name: "해킹시도",
            tax_email: "hack@evil.com",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(upsertBody!);
        // Non-whitelisted fields should NOT be in the payload
        assertEquals(parsed.biz_name, undefined);
        assertEquals(parsed.tax_email, undefined);
        // Only partner_id + 3 bank fields
        assertEquals(Object.keys(parsed).length, 4);
      });
    });
  },
});

// ─── UPSERT: missing partner_id → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for missing partner_id",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing partner_id");
      });
    });
  },
});

// ─── UPSERT: missing bank_name → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for missing bank_name",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing bank_name");
      });
    });
  },
});

// ─── UPSERT: missing account_holder → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for missing account_holder",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing account_holder");
      });
    });
  },
});

// ─── UPSERT: missing account_number → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for missing account_number",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing account_number");
      });
    });
  },
});

// ─── UPSERT: 403 no permission ───
Deno.test({
  name: "upsert_bank_account: returns 403 when user lacks SETTLEMENT_EDIT permission",
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
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});

// ─── UPSERT: 500 permission DB error ───
Deno.test({
  name: "upsert_bank_account: returns 500 when permission query fails",
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
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 500);
        const body = await readJson(res);
        assertEquals(body.error, "Failed to verify partner permissions");
      });
    });
  },
});

// ─── UPSERT: whitespace-only bank_name → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for whitespace-only bank_name",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "   ",
            account_holder: "홍길동",
            account_number: "3333011234567",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing bank_name");
      });
    });
  },
});

// ─── UPSERT: invalid account_number format → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for invalid account_number format",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "abc",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Invalid account_number format");
      });
    });
  },
});

// ─── UPSERT: account_number with hyphens → normalized ───
Deno.test({
  name: "upsert_bank_account: normalizes account_number by stripping hyphens",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") && req.method === "POST",
        handler: async (req) => {
          upsertBody = await req.clone().text();
          return new Response(null, { status: 200 });
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(upsertBody!);
        assertEquals(parsed.account_number, "3333011234567");
      });
    });
  },
});

// ─── UPSERT: 500 upsert error ───
Deno.test({
  name: "upsert_bank_account: returns 500 when upsert fails",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      upsertErrorRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_name: "카카오뱅크",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});
