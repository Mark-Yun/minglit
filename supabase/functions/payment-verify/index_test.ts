// payment-verify/index_test.ts — handler unit tests (L3, fake supabase)
//
// NOTE: IamportClient is instantiated INSIDE the handler (new IamportClient(IMP_KEY, IMP_SECRET)),
// so it cannot be dependency-injected. Tests that reach the PortOne call path mock globalThis.fetch
// to intercept the Iamport token + payment endpoints. Tests that short-circuit before PortOne
// (missing params, order not found, forbidden, already processed) need no fetch mock.
//
// The module-level guard `if (!IMP_KEY || !IMP_SECRET) throw` fires at import time, so we
// must set the env vars BEFORE importing the handler via dynamic import.
//
// Lazy-loads the handler via dynamic import with Deno.serve stubbed to prevent
// a real HTTP server from being started (same pattern as payment-webhook/index_test.ts).

Deno.env.set("PORTONE_API_KEY", "test-key");
Deno.env.set("PORTONE_API_SECRET", "test-secret");
Deno.env.set("MINGLIT_EF_TEST_FN_NAME", "payment-verify");
Deno.env.set("ENVIRONMENT", "dev");
Deno.env.set("SUPABASE_URL", "https://supabase.test");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "service-key");

import { assertEquals } from "jsr:@std/assert@1";
import {
  fakeSupabase,
  makeCtx,
  readJson,
  runHandler,
  type Handler,
} from "../_shared/_testing/mod.ts";

// Lazy-load to stub Deno.serve before the module fires minglitEdgeFunction (which calls Deno.serve).
// Env vars above are set synchronously at module init, so they're available when getHandler() runs.
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

// ── helpers ──────────────────────────────────────────────────────────────────

const ORDER_ID = "order-123";
const IMP_UID = "imp_123";
const USER_ID = "u-1";

function buildOrder(overrides: Record<string, unknown> = {}) {
  return {
    payment_amount: 10000,
    status: "pending",
    user_id: USER_ID,
    ...overrides,
  };
}

/** Mock fetch for happy-path PortOne calls: getToken + getPayment */
function makePortOneFetch(paymentOverrides: Record<string, unknown> = {}) {
  const mockPayment = {
    imp_uid: IMP_UID,
    merchant_uid: ORDER_ID,
    status: "paid",
    amount: 10000,
    paid_at: 1700000000,
    ...paymentOverrides,
  };

  return (input: string | URL | Request, _init?: RequestInit): Promise<Response> => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;

    // Token endpoint
    if (url.includes("/users/getToken")) {
      return Promise.resolve(
        new Response(JSON.stringify({ code: 0, response: { access_token: "tok-test" } }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );
    }
    // Payment lookup
    if (url.includes("/payments/")) {
      return Promise.resolve(
        new Response(JSON.stringify({ code: 0, response: mockPayment }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );
    }
    // Cancel endpoint (amount-mismatch path)
    if (url.includes("/payments/cancel")) {
      return Promise.resolve(
        new Response(JSON.stringify({ code: 0, response: {} }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
      );
    }
    return Promise.resolve(new Response("unexpected fetch: " + url, { status: 500 }));
  };
}

// ── tests ─────────────────────────────────────────────────────────────────────

Deno.test("payment-verify :: missing imp_uid → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { merchant_uid: ORDER_ID },
    ctx: makeCtx({ supabase: sb, userId: USER_ID }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing required parameters");
});

Deno.test("payment-verify :: missing merchant_uid → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { imp_uid: IMP_UID },
    ctx: makeCtx({ supabase: sb, userId: USER_ID }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing required parameters");
});

Deno.test("payment-verify :: order not found (DB error) → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    error: { message: "no rows", code: "PGRST116" },
  });
  const res = await runHandler(handler, {
    body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
    ctx: makeCtx({ supabase: sb, userId: USER_ID }),
  });
  assertEquals(res.status, 404);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Order not found");
});

Deno.test("payment-verify :: order belongs to different user → 403", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildOrder({ user_id: "other-user-999" }),
  });
  const res = await runHandler(handler, {
    body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
    ctx: makeCtx({ supabase: sb, userId: USER_ID }),
  });
  assertEquals(res.status, 403);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Forbidden");
});

Deno.test("payment-verify :: order already approved → 200 (idempotent early return)", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildOrder({ status: "approved" }),
  });
  const res = await runHandler(handler, {
    body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
    ctx: makeCtx({ supabase: sb, userId: USER_ID }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ success: boolean; message: string }>(res);
  assertEquals(body.success, true);
  assertEquals(body.message, "Already processed");
});

Deno.test("payment-verify :: order already paid → 200 (idempotent early return)", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildOrder({ status: "paid" }),
  });
  const res = await runHandler(handler, {
    body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
    ctx: makeCtx({ supabase: sb, userId: USER_ID }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ success: boolean; message: string }>(res);
  assertEquals(body.success, true);
  assertEquals(body.message, "Already processed");
});

Deno.test("payment-verify :: PortOne payment status != paid → 400", async () => {
  const handler = await getHandler();
  const origFetch = globalThis.fetch;
  globalThis.fetch = makePortOneFetch({ status: "ready" }) as typeof fetch;
  try {
    const sb = fakeSupabase().on("event_applications", "select", {
      data: buildOrder({ status: "pending" }),
    });
    const res = await runHandler(handler, {
      body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
      ctx: makeCtx({ supabase: sb, userId: USER_ID }),
    });
    assertEquals(res.status, 400);
    const body = await readJson<{ error: string }>(res);
    assertEquals(body.error, "Payment not completed");
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("payment-verify :: PortOne amount mismatch → 400 (cancel triggered)", async () => {
  const handler = await getHandler();
  const origFetch = globalThis.fetch;
  // PortOne returns amount=999 but order expects 10000
  globalThis.fetch = makePortOneFetch({ status: "paid", amount: 999 }) as typeof fetch;
  try {
    const sb = fakeSupabase().on("event_applications", "select", {
      data: buildOrder({ status: "pending", payment_amount: 10000 }),
    });
    const res = await runHandler(handler, {
      body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
      ctx: makeCtx({ supabase: sb, userId: USER_ID }),
    });
    assertEquals(res.status, 400);
    const body = await readJson<{ error: string; details: { expected: number; actual: number } }>(res);
    assertEquals(body.error, "Amount mismatch");
    assertEquals(body.details.expected, 10000);
    assertEquals(body.details.actual, 999);
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("payment-verify :: happy path → 200 + DB updated to approved", async () => {
  const handler = await getHandler();
  const origFetch = globalThis.fetch;
  globalThis.fetch = makePortOneFetch() as typeof fetch;
  try {
    const sb = fakeSupabase()
      .on("event_applications", "select", { data: buildOrder({ status: "pending" }) })
      .on("event_applications", "update", { error: null });

    const res = await runHandler(handler, {
      body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
      ctx: makeCtx({ supabase: sb, userId: USER_ID }),
    });
    assertEquals(res.status, 200);
    const body = await readJson<{ success: boolean; imp_uid: string }>(res);
    assertEquals(body.success, true);
    assertEquals(body.imp_uid, IMP_UID);

    // Assert DB update payload
    const [updateCall] = sb.callsFor("event_applications", "update");
    const patch = updateCall.payload as Record<string, unknown>;
    assertEquals(patch.status, "approved");
    assertEquals(patch.payment_id, IMP_UID);
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("payment-verify :: happy path with paid_at=null → approved with no paid_at in patch", async () => {
  const handler = await getHandler();
  const origFetch = globalThis.fetch;
  // paid_at=null means payment gateway didn't supply timestamp
  globalThis.fetch = makePortOneFetch({ paid_at: null }) as typeof fetch;
  try {
    const sb = fakeSupabase()
      .on("event_applications", "select", { data: buildOrder({ status: "pending" }) })
      .on("event_applications", "update", { error: null });

    const res = await runHandler(handler, {
      body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
      ctx: makeCtx({ supabase: sb, userId: USER_ID }),
    });
    assertEquals(res.status, 200);

    const [updateCall] = sb.callsFor("event_applications", "update");
    const patch = updateCall.payload as Record<string, unknown>;
    assertEquals(patch.status, "approved");
    // Fix #133: paid_at must NOT be set when missing — no fallback to now()
    assertEquals("paid_at" in patch, false);
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("payment-verify :: DB update fails after payment verified → 500", async () => {
  const handler = await getHandler();
  const origFetch = globalThis.fetch;
  globalThis.fetch = makePortOneFetch() as typeof fetch;
  try {
    const sb = fakeSupabase()
      .on("event_applications", "select", { data: buildOrder({ status: "pending" }) })
      .on("event_applications", "update", {
        error: { message: "db error", code: "23000" },
      });

    const res = await runHandler(handler, {
      body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
      ctx: makeCtx({ supabase: sb, userId: USER_ID }),
    });
    assertEquals(res.status, 500);
    const body = await readJson<{ error: string }>(res);
    assertEquals(body.error, "Failed to update order status");
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("payment-verify :: PortOne getToken network failure → 500 (catch block)", async () => {
  const handler = await getHandler();
  const origFetch = globalThis.fetch;
  globalThis.fetch = (_input: unknown, _init?: unknown): Promise<Response> => {
    return Promise.resolve(new Response("Iamport down", { status: 503 }));
  };
  try {
    const sb = fakeSupabase().on("event_applications", "select", {
      data: buildOrder({ status: "pending" }),
    });
    const res = await runHandler(handler, {
      body: { imp_uid: IMP_UID, merchant_uid: ORDER_ID },
      ctx: makeCtx({ supabase: sb, userId: USER_ID }),
    });
    assertEquals(res.status, 500);
  } finally {
    globalThis.fetch = origFetch;
  }
});
