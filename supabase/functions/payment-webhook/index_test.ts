// payment-webhook/index_test.ts — L3 handler unit tests (fake supabase + mocked fetch)
//
// Pattern: runHandler(handler, { body, ctx: makeCtx({ supabase: sb }) })
// This calls the raw handler directly — bypasses the minglitEdgeFunction wrapper
// (no IP allowlist, no JWT check). L4 integration tests cover the wrapper path.
//
// PortOne API (IamportClient) is instantiated inside the handler and calls
// globalThis.fetch — mocked via withMockedFetch from _test_utils/mock_http.ts.
//
// PORTONE_API_KEY / PORTONE_API_SECRET are read at module top-level in index.ts;
// they must be set BEFORE index.ts is first evaluated. Since static `import`
// statements are hoisted and run before the module body, we cannot use
// Deno.env.set before a static import. Instead, we lazily load the handler via
// dynamic import with env vars set first.
//
// NOTE: this EF returns plain `new Response(...)` (not successResponse/errorResponse),
// so body assertions use res.text() / .json() directly.

import { assertEquals } from "@std/assert";
import {
  fakeSupabase,
  makeCtx,
  runHandler,
  type Handler,
} from "../_shared/_testing/mod.ts";
import { createFetchMock, withEnv, withMockedFetch } from "../_test_utils/mock_http.ts";

const PORTONE_ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
};

/** Lazily loaded handler — set env vars first, then dynamic-import index.ts.
 *
 * index.ts calls `minglitEdgeFunction(handler)` at module top-level which in turn
 * calls Deno.serve(). We stub Deno.serve to a no-op during the import so no real
 * HTTP server is started (same technique as captureServeHandler in _test_utils).
 */
let _handler: Handler | null = null;
async function getHandler(): Promise<Handler> {
  if (_handler) return _handler;

  // Stub Deno.serve to prevent a real HTTP server from being started.
  const denoAsAny = Deno as unknown as { serve: (...args: unknown[]) => Deno.HttpServer };
  const originalServe = denoAsAny.serve;
  denoAsAny.serve = () => ({ shutdown() {}, finished: Promise.resolve() } as Deno.HttpServer);

  // Stub setInterval to prevent background timers (e.g. Statsig flush).
  const originalSetInterval = globalThis.setInterval;
  const originalClearInterval = globalThis.clearInterval;
  globalThis.setInterval = ((_cb: () => void) => 0 as unknown as ReturnType<typeof setInterval>) as typeof setInterval;
  globalThis.clearInterval = ((_id?: ReturnType<typeof setInterval>) => {}) as typeof clearInterval;

  try {
    _handler = await withEnv(PORTONE_ENV, async () => {
      const mod = await import(`./index.ts?unit=${crypto.randomUUID()}`);
      return mod.handler as Handler;
    });
  } finally {
    denoAsAny.serve = originalServe;
    globalThis.setInterval = originalSetInterval;
    globalThis.clearInterval = originalClearInterval;
  }

  return _handler!;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Minimal PortOne mock: getToken + getPayment returning the given status. */
function portoneOkFetch(
  impUid: string,
  merchantUid: string,
  status: string,
  extra: Record<string, unknown> = {},
) {
  const { fetchMock } = createFetchMock([
    {
      matcher: "users/getToken",
      handler: () =>
        new Response(
          JSON.stringify({ code: 0, response: { access_token: "tok" } }),
          { headers: { "Content-Type": "application/json" } },
        ),
    },
    {
      matcher: `payments/${impUid}`,
      handler: () =>
        new Response(
          JSON.stringify({
            code: 0,
            response: {
              imp_uid: impUid,
              merchant_uid: merchantUid,
              status,
              amount: 15000,
              paid_at: null,
              ...extra,
            },
          }),
          { headers: { "Content-Type": "application/json" } },
        ),
    },
  ]);
  return fetchMock;
}

/** ctx with system auth (this EF uses service-role supabase via the wrapper;
 *  in unit tests we inject the fake directly regardless of auth type). */
function sysCtx(sb: ReturnType<typeof fakeSupabase>) {
  return makeCtx({ supabase: sb, auth: { type: "system" } });
}

// ---------------------------------------------------------------------------
// 1. Malformed JSON → 400
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: malformed JSON body → 400", async () => {
  const h = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const { fetchMock } = createFetchMock([]);
  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: "not-json{{{",
      headers: { "content-type": "text/plain" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 400);
  assertEquals(await res.text(), "Bad Request");
});

// ---------------------------------------------------------------------------
// 2. Missing imp_uid → 400
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: missing imp_uid → 400", async () => {
  const h = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const { fetchMock } = createFetchMock([]);
  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { merchant_uid: "order-1", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 400);
  assertEquals(await res.text(), "Missing parameters");
});

// ---------------------------------------------------------------------------
// 3. Missing merchant_uid → 400
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: missing merchant_uid → 400", async () => {
  const h = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const { fetchMock } = createFetchMock([]);
  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-1", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 400);
  assertEquals(await res.text(), "Missing parameters");
});

// ---------------------------------------------------------------------------
// 4. Idempotency: existing log → 200, no PortOne call, no DB update
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: duplicate imp_uid (already processed) → 200 early exit", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: { imp_uid: "imp-dup" } });

  let portoneCallCount = 0;
  const { fetchMock } = createFetchMock([
    {
      matcher: () => { portoneCallCount++; return false; },
      handler: () => new Response("should not reach", { status: 500 }),
    },
  ]);

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-dup", merchant_uid: "order-dup", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);
  assertEquals(await res.text(), "OK");
  assertEquals(sb.callsFor("event_applications", "update").length, 0);
  assertEquals(portoneCallCount, 0);
});

// ---------------------------------------------------------------------------
// 5. Merchant UID mismatch → 400
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: merchant_uid mismatch → 400", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null });

  const fetchMock = portoneOkFetch("imp-1", "DIFFERENT-ORDER", "paid");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-1", merchant_uid: "order-1", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 400);
  assertEquals(await res.text(), "Merchant UID mismatch");
  assertEquals(sb.callsFor("event_applications", "update").length, 0);
});

// ---------------------------------------------------------------------------
// 6. status=paid → dbStatus "approved" + DB update + notification queued
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: paid → dbStatus=approved, notification enqueued → 200", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null })
    .on("event_applications", "select", {
      data: { user_id: "u-1", event_id: "ev-1" },
    })
    .on("pgmq_send", "rpc", { data: null, error: null });

  const fetchMock = portoneOkFetch("imp-paid", "order-paid", "paid", { paid_at: 1700000000 });

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-paid", merchant_uid: "order-paid", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);

  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  assertEquals(patch.status, "approved");
  // paid status does not set refund_status
  assertEquals(typeof patch.refund_status, "undefined");
  // paid_at converted from epoch seconds to ISO string
  assertEquals(typeof patch.paid_at, "string");

  // Notification RPC was queued
  assertEquals(sb.callsFor("pgmq_send", "rpc").length, 1);
});

// ---------------------------------------------------------------------------
// 7. status=paid + paid_at=null → no paid_at in update payload
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: paid but paid_at=null → paid_at omitted from update", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null })
    .on("event_applications", "select", {
      data: { user_id: "u-2", event_id: "ev-2" },
    })
    .on("pgmq_send", "rpc", { data: null, error: null });

  const fetchMock = portoneOkFetch("imp-nopaidat", "order-nopaidat", "paid", { paid_at: null });

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-nopaidat", merchant_uid: "order-nopaidat", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);
  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  // Fix #133: paid_at=null must not be set (no fallback to now())
  assertEquals(patch.paid_at, undefined);
  assertEquals(patch.status, "approved");
});

// ---------------------------------------------------------------------------
// 8. status=cancelled → dbStatus "cancelled" + refund_status="completed"
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: cancelled → dbStatus=cancelled + refund_status=completed → 200", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null });

  const fetchMock = portoneOkFetch("imp-cancel", "order-cancel", "cancelled");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-cancel", merchant_uid: "order-cancel", status: "cancelled" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);

  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  assertEquals(patch.status, "cancelled");
  assertEquals(patch.refund_status, "completed");
});

// ---------------------------------------------------------------------------
// 9. status=failed → dbStatus "payment_failed", no notification
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: failed → dbStatus=payment_failed, no notification → 200", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null });

  const fetchMock = portoneOkFetch("imp-fail", "order-fail", "failed");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-fail", merchant_uid: "order-fail", status: "failed" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);

  const [updateCall] = sb.callsFor("event_applications", "update");
  assertEquals((updateCall.payload as Record<string, unknown>).status, "payment_failed");
  // No pgmq_send for failed payments (only for paid)
  assertEquals(sb.callsFor("pgmq_send", "rpc").length, 0);
});

// ---------------------------------------------------------------------------
// 10. status=ready → dbStatus "payment_pending"
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: ready (가상계좌) → dbStatus=payment_pending → 200", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null });

  const fetchMock = portoneOkFetch("imp-ready", "order-ready", "ready");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-ready", merchant_uid: "order-ready", status: "ready" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);

  const [updateCall] = sb.callsFor("event_applications", "update");
  assertEquals((updateCall.payload as Record<string, unknown>).status, "payment_pending");
});

// ---------------------------------------------------------------------------
// 11. status=unknown (default branch) → dbStatus "unknown_<value>"
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: unknown status → dbStatus=unknown_<value> → 200", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null });

  const fetchMock = portoneOkFetch("imp-unk", "order-unk", "awaiting_something");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-unk", merchant_uid: "order-unk", status: "awaiting_something" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);

  const [updateCall] = sb.callsFor("event_applications", "update");
  assertEquals(
    (updateCall.payload as Record<string, unknown>).status,
    "unknown_awaiting_something",
  );
});

// ---------------------------------------------------------------------------
// 12. DB update error → 500
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: DB update error → 500", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", {
      error: { message: "DB constraint violation", code: "23503" },
    });

  const fetchMock = portoneOkFetch("imp-dberr", "order-dberr", "paid");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-dberr", merchant_uid: "order-dberr", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 500);
  assertEquals(await res.text(), "DB Error");
});

// ---------------------------------------------------------------------------
// 13. PortOne getToken failure → 500
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: PortOne getToken failure → 500", async () => {
  const h = await getHandler();
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null });

  const { fetchMock } = createFetchMock([
    {
      matcher: "users/getToken",
      handler: () => new Response("Service Unavailable", { status: 503 }),
    },
  ]);

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-pgfail", merchant_uid: "order-pgfail", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 500);
  assertEquals(sb.callsFor("event_applications", "update").length, 0);
});

// ---------------------------------------------------------------------------
// 14. paid → idempotency log inserted after successful DB update
// ---------------------------------------------------------------------------
Deno.test("payment-webhook :: paid → webhook_imp_uid_log inserted after successful update", async () => {
  const h = await getHandler();
  // application select returns null → no notification branch; avoids extra scripts
  const sb = fakeSupabase()
    .on("webhook_imp_uid_log", "select", { data: null })
    .on("event_applications", "update", { error: null })
    .on("webhook_imp_uid_log", "insert", { error: null })
    .on("event_applications", "select", { data: null });

  const fetchMock = portoneOkFetch("imp-log", "order-log", "paid");

  const res = await withMockedFetch(fetchMock, () =>
    runHandler(h, {
      body: { imp_uid: "imp-log", merchant_uid: "order-log", status: "paid" },
      ctx: sysCtx(sb),
    })
  );
  assertEquals(res.status, 200);

  const insertCalls = sb.callsFor("webhook_imp_uid_log", "insert");
  assertEquals(insertCalls.length, 1);
  const payload = insertCalls[0].payload as Record<string, unknown>;
  assertEquals(payload.imp_uid, "imp-log");
  assertEquals(payload.merchant_uid, "order-log");
});
