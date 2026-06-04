import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  type FetchRoute,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const TEST_USER_ID = "user-partner-owner";
const TEST_PARTNER_ID = "partner-001";

const ENV = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "partner-manage-settlement",
};

function authRoute(): FetchRoute {
  return {
    matcher: "/auth/v1/user",
    handler: () =>
      jsonResponse({ id: TEST_USER_ID, email: "partner@test.com" }),
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
          ? {
            permissions: ["PARTNER_EDIT", "SETTLEMENT_EDIT", "SETTLEMENT_VIEW"],
          }
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

function manualReviewRoute(): FetchRoute {
  return {
    matcher: (req) =>
      req.url.includes("/rest/v1/partner_settlements") &&
      req.method === "PATCH",
    handler: () => new Response(null, { status: 200 }),
  };
}

// ─── CORS preflight ───
Deno.test({
  name: "handles OPTIONS preflight request",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {}),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, 'Missing or invalid "action" field');
      });
    });
  },
});

// ─── 400: unknown action ───
Deno.test({
  name: "returns 400 for unknown action",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
            bank_code: "kakao",
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") &&
          req.method === "POST",
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
            bank_code: "kakao",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(upsertBody!);
        assertEquals(parsed.partner_id, TEST_PARTNER_ID);
        assertEquals(parsed.bank_code, "kakao");
        assertEquals(parsed.bank_name, "카카오뱅크");
        assertEquals(parsed.account_holder, "홍길동");
        // account_number is normalized: hyphens stripped
        assertEquals(parsed.account_number, "3333011234567");
        assertEquals(parsed.bank_verification_status, "manual_review_pending");
        assertEquals(
          parsed.bank_verification_reason,
          "partner_submitted_bank_account",
        );
        assertEquals(parsed.bank_verified_at, null);
      });
    });
  },
});

// ─── UPSERT: legacy bank_name-only clients ───
Deno.test({
  name: "upsert_bank_account: accepts legacy bank_name-only requests",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") &&
          req.method === "POST",
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
            bank_name: "국민은행",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 200);
        const parsed = JSON.parse(upsertBody!);
        assertEquals(parsed.partner_id, TEST_PARTNER_ID);
        assertEquals(parsed.bank_code, null);
        assertEquals(parsed.bank_name, "국민은행");
        assertEquals(parsed.account_holder, "홍길동");
        assertEquals(parsed.account_number, "3333011234567");
        assertEquals(parsed.bank_verification_status, "manual_review_pending");
      });
    });
  },
});

// ─── UPSERT: extra fields ignored ───
Deno.test({
  name: "upsert_bank_account: ignores non-whitelisted fields",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") &&
          req.method === "POST",
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
            bank_code: "kakao",
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
        assertEquals(parsed.bank_code, "kakao");
        assertEquals(parsed.bank_verification_status, "manual_review_pending");
      });
    });
  },
});

// ─── UPSERT: missing partner_id → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for missing partner_id",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  name: "upsert_bank_account: returns 400 for missing bank_code",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
        assertEquals(body.error, "Missing or unsupported bank_code");
      });
    });
  },
});

// ─── UPSERT: missing account_holder → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for missing account_holder",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
  name:
    "upsert_bank_account: returns 403 when user lacks SETTLEMENT_EDIT permission",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
            bank_code: "kakao",
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
            bank_code: "kakao",
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

// ─── UPSERT: whitespace-only bank_code → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for whitespace-only bank_code",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_code: "   ",
            account_holder: "홍길동",
            account_number: "3333011234567",
          }),
        );
        assertEquals(res.status, 400);
        const body = await readJson(res);
        assertEquals(body.error, "Missing or unsupported bank_code");
      });
    });
  },
});

// ─── UPSERT: invalid account_number format → 400 ───
Deno.test({
  name: "upsert_bank_account: returns 400 for invalid account_number format",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "upsert_bank_account",
            partner_id: TEST_PARTNER_ID,
            bank_code: "kakao",
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    let upsertBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") &&
          req.method === "POST",
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
            bank_code: "kakao",
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
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
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
            bank_code: "kakao",
            account_holder: "홍길동",
            account_number: "3333-01-1234567",
          }),
        );
        assertEquals(res.status, 500);
      });
    });
  },
});

// ─── MANUAL REVIEW: success ───
Deno.test({
  name:
    "request_manual_bank_account_review: moves account to manual_review_pending",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    let updateBody: string | null = null;

    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(),
      {
        matcher: (req) =>
          req.url.includes("/rest/v1/partner_settlements") &&
          req.method === "PATCH",
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
            action: "request_manual_bank_account_review",
            partner_id: TEST_PARTNER_ID,
          }),
        );
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(body.bank_verification_status, "manual_review_pending");

        const parsed = JSON.parse(updateBody!);
        assertEquals(parsed.bank_verification_status, "manual_review_pending");
        assertEquals(
          parsed.bank_verification_reason,
          "partner_requested_manual_review",
        );
        assertEquals(parsed.bank_verified_at, null);
      });
    });
  },
});

// ─── MANUAL REVIEW: 403 no permission ───
Deno.test({
  name:
    "request_manual_bank_account_review: returns 403 without SETTLEMENT_EDIT",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      permRoute(false),
      manualReviewRoute(),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          authenticatedJsonRequest("http://localhost", {
            action: "request_manual_bank_account_review",
            partner_id: TEST_PARTNER_ID,
          }),
        );
        assertEquals(res.status, 403);
      });
    });
  },
});
