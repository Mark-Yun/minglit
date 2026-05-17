// payment-cancel/index_test.ts — handler unit tests (L3, fakeSupabase)
//
// Pattern mirrors user-cancel-order/index_test.ts:
//   fakeSupabase() scripts DB responses, runHandler() calls the exported handler directly.
//   PortOne HTTP calls (executeRefund) are intercepted via withMockedFetch + withEnv.
//
// Lazy-loads the handler via dynamic import with Deno.serve stubbed to prevent
// a real HTTP server from being started (same pattern as payment-webhook/index_test.ts).

import { assertEquals } from "@std/assert";
import {
  fakeSupabase,
  makeCtx,
  readJson,
  runHandler,
  type Handler,
} from "../_shared/_testing/mod.ts";
import {
  createFetchMock,
  jsonResponse,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

let _handler: Handler | null = null;
async function getHandler(): Promise<Handler> {
  if (_handler) return _handler;
  const denoAsAny = Deno as unknown as { serve: (...args: unknown[]) => Deno.HttpServer };
  const origServe = denoAsAny.serve;
  denoAsAny.serve = () => ({ shutdown() {}, finished: Promise.resolve() } as Deno.HttpServer);
  const origSetInterval = globalThis.setInterval;
  const origClearInterval = globalThis.clearInterval;
  globalThis.setInterval = ((_cb: () => void) => 0 as unknown as ReturnType<typeof setInterval>) as typeof setInterval;
  globalThis.clearInterval = ((_id?: ReturnType<typeof setInterval>) => {}) as typeof clearInterval;
  try {
    _handler = (await import(`./index.ts?unit=${crypto.randomUUID()}`)).handler as Handler;
  } finally {
    denoAsAny.serve = origServe;
    globalThis.setInterval = origSetInterval;
    globalThis.clearInterval = origClearInterval;
  }
  return _handler!;
}

// ── Shared time fixtures ──────────────────────────────────────────────────────
const nowMs = Date.now();
const ELIGIBLE_PAID_AT = new Date(nowMs - 1 * 60 * 60 * 1000).toISOString(); // 1h ago — within 2h grace
const INELIGIBLE_PAID_AT = new Date(nowMs - 3 * 60 * 60 * 1000).toISOString(); // 3h ago — outside grace
const FAR_FUTURE_EVENT = new Date(nowMs + 10 * 24 * 60 * 60 * 1000).toISOString(); // 10d → within cutoff
const NEAR_FUTURE_EVENT = new Date(nowMs + 3 * 24 * 60 * 60 * 1000).toISOString(); // 3d → outside 7d cutoff
const PAST_EVENT = new Date(nowMs - 60 * 60 * 1000).toISOString(); // already started

// ── Shared env required by executeRefund ─────────────────────────────────────
const PORTONE_ENV = {
  PORTONE_API_KEY: "test-key",
  PORTONE_API_SECRET: "test-secret",
};

// ── PortOne stub routes ───────────────────────────────────────────────────────
const portoneTokenRoute = {
  matcher: "https://api.iamport.kr/users/getToken",
  handler: () => jsonResponse({ code: 0, response: { access_token: "tok" } }),
};

const portoneCancelRoute = {
  matcher: "https://api.iamport.kr/payments/cancel",
  handler: () => jsonResponse({ code: 0, response: { status: "cancelled", amount: 15000 } }),
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Standard application row returned from event_applications select */
function makeApp(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    paid_at: ELIGIBLE_PAID_AT,
    event_id: "ev-1",
    refund_status: "none",
    user_id: "u-1",
    ...overrides,
  };
}

// ── Test cases ────────────────────────────────────────────────────────────────

// 1. Missing payment_id → 400
Deno.test("payment-cancel :: missing payment_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { reason: "no id" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing payment_id");
});

// 2. Application not found (DB returns error) → 404
Deno.test("payment-cancel :: application not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    error: { message: "no rows", code: "PGRST116" },
  });
  const res = await runHandler(handler, {
    body: { payment_id: "imp_unknown" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Application not found");
});

// 3. Application belongs to a different user → 403
Deno.test("payment-cancel :: wrong user → 403", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: makeApp({ user_id: "other-user" }),
  });
  const res = await runHandler(handler, {
    body: { payment_id: "imp_123" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }), // u-1 ≠ other-user
  });
  assertEquals(res.status, 403);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Forbidden");
});

// 4. Already refunded (refund_status ≠ "none") → 400
Deno.test("payment-cancel :: already refunded → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: makeApp({ refund_status: "completed" }),
  });
  const res = await runHandler(handler, {
    body: { payment_id: "imp_123" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "already_refunded");
});

// 5. Event fetch fails → 500
Deno.test("payment-cancel :: event fetch error → 500", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: makeApp() })
    .on("events", "select", { error: { message: "connection timeout" } })
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } });

  const res = await runHandler(handler, {
    body: { payment_id: "imp_123" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 500);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Failed to verify refund eligibility");
});

// 6. Policy RPC fails → 500
Deno.test("payment-cancel :: policy rpc error → 500", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: makeApp() })
    .on("events", "select", { data: { start_time: FAR_FUTURE_EVENT } })
    .on("get_current_policy", "rpc", { error: { message: "rpc failed" } });

  const res = await runHandler(handler, {
    body: { payment_id: "imp_123" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 500);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Failed to verify refund eligibility");
});

// 7. Refund ineligible — event already started → 400
Deno.test("payment-cancel :: event already started → 400 refund_not_eligible", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", {
      data: makeApp({ paid_at: ELIGIBLE_PAID_AT }),
    })
    .on("events", "select", { data: { start_time: PAST_EVENT } })
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } });

  const res = await runHandler(handler, {
    body: { payment_id: "imp_123" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string; details?: { reason?: string } }>(res);
  assertEquals(body.error, "refund_not_eligible");
});

// 8. Refund ineligible — outside grace + outside cutoff → 400
Deno.test("payment-cancel :: outside grace and cutoff window → 400 refund_not_eligible", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", {
      data: makeApp({ paid_at: INELIGIBLE_PAID_AT }), // 3h ago — outside 2h grace
    })
    .on("events", "select", { data: { start_time: NEAR_FUTURE_EVENT } }) // 3d — outside 7d cutoff
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } });

  const res = await runHandler(handler, {
    body: { payment_id: "imp_123" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "refund_not_eligible");
});

// 9. PortOne credentials missing → 500 (RefundError from executeRefund)
Deno.test("payment-cancel :: missing portone credentials → 500", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: makeApp() })
    .on("events", "select", { data: { start_time: FAR_FUTURE_EVENT } })
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } });

  // Explicitly unset credentials so executeRefund throws RefundError("Server configuration error", 500)
  await withEnv(
    { PORTONE_API_KEY: undefined, PORTONE_API_SECRET: undefined },
    async () => {
      const res = await runHandler(handler, {
        body: { payment_id: "imp_123" },
        ctx: makeCtx({ supabase: sb, userId: "u-1" }),
      });
      assertEquals(res.status, 500);
      const body = await readJson<{ error: string }>(res);
      assertEquals(body.error, "Server configuration error");
    },
  );
});

// 10. Happy path — within grace period → 200, DB updated with refund_status=completed
Deno.test("payment-cancel :: happy path (within grace) → 200 + refund_status=completed", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", {
      data: makeApp({ paid_at: ELIGIBLE_PAID_AT }),
    })
    .on("events", "select", { data: { start_time: NEAR_FUTURE_EVENT } })
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } })
    .on("event_applications", "update", { error: null });

  const { fetchMock } = createFetchMock([portoneTokenRoute, portoneCancelRoute]);

  await withEnv(PORTONE_ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const res = await runHandler(handler, {
        body: { payment_id: "imp_123", reason: "test refund" },
        ctx: makeCtx({ supabase: sb, userId: "u-1" }),
      });
      assertEquals(res.status, 200);
      const body = await readJson<{ success: boolean }>(res);
      assertEquals(body.success, true);

      // Verify DB update payload
      const [updateCall] = sb.callsFor("event_applications", "update");
      const patch = updateCall.payload as Record<string, unknown>;
      assertEquals(patch.refund_status, "completed");
      assertEquals(typeof patch.refunded_at, "string");
      // Fix #2099: refund_amount set from PortOne response when not passed
      assertEquals(patch.refund_amount, 15000);
    });
  });
});

// 11. Happy path — paidAt null but within cutoff → 200
Deno.test("payment-cancel :: paidAt=null + within cutoff → 200", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", {
      data: makeApp({ paid_at: null }),
    })
    .on("events", "select", { data: { start_time: FAR_FUTURE_EVENT } }) // 10d → within 7d cutoff
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } })
    .on("event_applications", "update", { error: null });

  const { fetchMock } = createFetchMock([portoneTokenRoute, portoneCancelRoute]);

  await withEnv(PORTONE_ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const res = await runHandler(handler, {
        body: { payment_id: "imp_123" },
        ctx: makeCtx({ supabase: sb, userId: "u-1" }),
      });
      assertEquals(res.status, 200);
    });
  });
});

// 12. PortOne token failure → 502 (RefundError wrapped by executeRefund)
Deno.test("payment-cancel :: portone token failure → 502", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: makeApp() })
    .on("events", "select", { data: { start_time: FAR_FUTURE_EVENT } })
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } });

  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.iamport.kr/users/getToken",
      handler: () => jsonResponse({ code: 1, message: "bad credentials" }),
    },
  ]);

  await withEnv(PORTONE_ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const res = await runHandler(handler, {
        body: { payment_id: "imp_123" },
        ctx: makeCtx({ supabase: sb, userId: "u-1" }),
      });
      assertEquals(res.status, 502);
      const body = await readJson<{ error: string }>(res);
      assertEquals(body.error, "Payment provider error");
    });
  });
});

// 13. DB update error after successful refund — non-fatal, still 200
Deno.test("payment-cancel :: DB update error is non-fatal → 200", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: makeApp() })
    .on("events", "select", { data: { start_time: FAR_FUTURE_EVENT } })
    .on("get_current_policy", "rpc", { data: { grace_period_hours: 2, cutoff_days: 7 } })
    .on("event_applications", "update", { error: { message: "DB error", code: "XXXXX" } });

  const { fetchMock } = createFetchMock([portoneTokenRoute, portoneCancelRoute]);

  await withEnv(PORTONE_ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const res = await runHandler(handler, {
        body: { payment_id: "imp_123" },
        ctx: makeCtx({ supabase: sb, userId: "u-1" }),
      });
      // Non-fatal per source comment: "payment was cancelled, just log the DB error"
      assertEquals(res.status, 200);
      const body = await readJson<{ success: boolean }>(res);
      assertEquals(body.success, true);
    });
  });
});
