// user-cancel-order/index_test.ts — handler unit tests (L3, fake supabase)
//
// Lazy-loads the handler via dynamic import with Deno.serve stubbed to prevent
// a real HTTP server from being started (same pattern as payment-webhook/index_test.ts).

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildApplication,
  fakeSupabase,
  makeCtx,
  readJson,
  runHandler,
  type Handler,
} from "../_shared/_testing/mod.ts";

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

Deno.test("user-cancel-order :: application not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    error: { message: "no rows", code: "PGRST116" },
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

Deno.test("user-cancel-order :: missing event_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase();
  const res = await runHandler(handler, {
    body: {},
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});

Deno.test("user-cancel-order :: status=cancelled (final) → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildApplication({ status: "cancelled" }),
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});

Deno.test("user-cancel-order :: status=pending (pre-payment) → 200 + 2 deletes", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildApplication({ status: "pending" }) })
    .on("verification_submissions", "delete", { error: null })
    .on("event_applications", "delete", { error: null });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ success: boolean; type: string }>(res);
  assertEquals(body.success, true);
  assertEquals(body.type, "cancelled");
  // 호출 sequence 검증
  assertEquals(sb.callsFor("verification_submissions", "delete").length, 1);
  assertEquals(sb.callsFor("event_applications", "delete").length, 1);
});

Deno.test("user-cancel-order :: free event (paid + amount=0 + 이벤트 미시작) → 200 + status update", async () => {
  const handler = await getHandler();
  const futureEvent = "2099-12-31T18:00:00Z";
  const sb = fakeSupabase()
    .on("event_applications", "select", {
      data: buildApplication({
        status: "paid",
        payment_amount: 0,
        paid_at: "2026-01-01T00:00:00Z",
      }),
    })
    .on("events", "select", { data: { start_time: futureEvent } })
    .on("event_applications", "update", { error: null });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ success: boolean; type: string }>(res);
  assertEquals(body.type, "cancelled");
  // status=cancelled 로 업데이트되는지 확인
  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  assertEquals(patch.status, "cancelled");
  assertEquals(patch.cancellation_reason, "user_requested");
});

Deno.test("user-cancel-order :: free event but 이벤트 이미 시작 → 400 (event_already_started)", async () => {
  const handler = await getHandler();
  const pastEvent = "2020-01-01T00:00:00Z";
  const sb = fakeSupabase()
    .on("event_applications", "select", {
      data: buildApplication({ status: "paid", payment_amount: 0 }),
    })
    .on("events", "select", { data: { start_time: pastEvent } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string; details?: { reason?: string } }>(res);
  assertEquals(body.error, "refund_not_eligible");
  assertEquals(body.details?.reason, "event_already_started");
});

Deno.test("user-cancel-order :: paid + refund_status=completed → 400 (already_refunded)", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildApplication({
      status: "paid",
      payment_amount: 15000,
      refund_status: "completed",
    }),
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});

Deno.test("user-cancel-order :: paid + payment_amount=null (damaged data) → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildApplication({ status: "paid", payment_amount: null }),
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});
