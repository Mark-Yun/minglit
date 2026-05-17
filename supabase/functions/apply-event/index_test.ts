// apply-event/index_test.ts — handler unit tests (L3, fake supabase)
//
// Lazy-loads the handler via dynamic import with Deno.serve stubbed to prevent
// a real HTTP server from being started (same pattern as payment-webhook/index_test.ts).

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildApplication,
  buildEvent,
  buildTicket,
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

// ─── helpers ────────────────────────────────────────────────────────────────

const BASE_BODY = { event_id: "ev-1", ticket_id: "tk-1" };

// ─── 1. missing params ──────────────────────────────────────────────────────

Deno.test("apply-event :: missing event_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase();
  const res = await runHandler(handler, {
    body: { ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});

Deno.test("apply-event :: missing ticket_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase();
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});

// ─── 2. event not found ──────────────────────────────────────────────────────

Deno.test("apply-event :: event not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("events", "select", {
    error: { message: "no rows", code: "PGRST116" },
  });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

// ─── 3. event status not "scheduled" → 409 ──────────────────────────────────

Deno.test("apply-event :: event status=active → 409 (scheduled only)", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("events", "select", {
    data: buildEvent({ status: "active" }),
  });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Event is not accepting applications");
});

Deno.test("apply-event :: event status=cancelled → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("events", "select", {
    data: buildEvent({ status: "cancelled" }),
  });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
});

// ─── 4. event full → 409 ────────────────────────────────────────────────────

Deno.test("apply-event :: event full (current >= max) → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("events", "select", {
    data: buildEvent({ current_participants: 30, max_participants: 30 }),
  });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Event is at full capacity");
});

// ─── 5. ticket not found → 404 ──────────────────────────────────────────────

Deno.test("apply-event :: ticket not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { error: { message: "no rows", code: "PGRST116" } });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

// ─── 6. ticket belongs to different event → 400 ─────────────────────────────

Deno.test("apply-event :: ticket event_id mismatch → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent({ id: "ev-1" }) })
    .on("tickets", "select", {
      data: buildTicket({ id: "tk-1", event_id: "ev-DIFFERENT" }),
    });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Ticket does not belong to this event");
});

// ─── 7. ticket status not "on_sale" → 409 ───────────────────────────────────

Deno.test("apply-event :: ticket status=sold_out (status field) → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", {
      data: buildTicket({ status: "closed" }),
    });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Ticket is not available");
});

// ─── 8. ticket sold out (quantity guard) → 409 ──────────────────────────────

Deno.test("apply-event :: ticket sold out (sold_count >= quantity) → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", {
      data: buildTicket({ quantity: 10, sold_count: 10 }),
    });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Ticket is sold out");
});

// ─── 9. duplicate application (blocks re-application) → 409 ─────────────────

Deno.test("apply-event :: duplicate application (status=pending) → 409 ALREADY_APPLIED", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("event_applications", "select", {
      data: buildApplication({ status: "pending", event_id: "ev-1", user_id: "u-1" }),
    });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Already applied to this event");
});

// ─── 10. verification requirements not met → 403 ────────────────────────────

Deno.test("apply-event :: verification requirements not met → 403", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", {
      data: buildTicket({ required_verification_ids: ["verif-A"] }),
    })
    .on("event_applications", "select", { data: null }) // no existing app
    .on("user_verifications", "select", { data: [] }); // user has none
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 403);
  const body = await readJson<{ error: string; details: { missing_verification_ids: string[] } }>(res);
  assertEquals(body.error, "Eligibility requirements not met");
  assertEquals(body.details.missing_verification_ids, ["verif-A"]);
});

// ─── 11. free ticket — happy path (new application via RPC) → 200 ────────────

Deno.test("apply-event :: free ticket, new application → 200 type=free via RPC", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket({ price: 0 }) })
    .on("event_applications", "select", { data: null }) // no existing app
    .on("apply_event", "rpc", { data: "app-new-1" }); // RPC returns application id
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ type: string; application_id: string }>(res);
  assertEquals(body.type, "free");
  assertEquals(body.application_id, "app-new-1");
  // RPC was called
  assertEquals(sb.callsFor("apply_event", "rpc").length, 1);
});

// ─── 12. paid ticket — happy path (new application via insert) → 200 ─────────

Deno.test("apply-event :: paid ticket, new application → 200 type=paid", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket({ price: 15000 }) })
    .on("event_applications", "select", { data: null }) // no existing app
    .on("check_party_balance", "rpc", { data: { allowed: true, reason: null } })
    .on("event_applications", "insert", { error: null });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ type: string; payment_amount: number }>(res);
  assertEquals(body.type, "paid");
  assertEquals(body.payment_amount, 15000);
  // application insert was called
  assertEquals(sb.callsFor("event_applications", "insert").length, 1);
  const [insertCall] = sb.callsFor("event_applications", "insert");
  const payload = insertCall.payload as Record<string, unknown>;
  assertEquals(payload.status, "payment_pending");
  assertEquals(payload.payment_amount, 15000);
});

// ─── 13. paid ticket — balance check fails → 409 ────────────────────────────

Deno.test("apply-event :: paid ticket, balance check blocked → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket({ price: 15000 }) })
    .on("event_applications", "select", { data: null })
    .on("check_party_balance", "rpc", {
      data: { allowed: false, reason: "성비 균형 제한" },
    });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "성비 균형 제한");
});

// ─── 14. free re-application (cancelled before) → 200 + UPDATE (not RPC) ────

Deno.test("apply-event :: free ticket, cancelled re-application → 200 + update (no RPC)", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket({ price: 0 }) })
    .on("event_applications", "select", {
      data: buildApplication({ id: "app-old", status: "cancelled", event_id: "ev-1", user_id: "u-1" }),
    })
    .on("check_party_balance", "rpc", { data: { allowed: true, reason: null } })
    .on("event_applications", "update", { error: null });
  const res = await runHandler(handler, {
    body: BASE_BODY,
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ type: string; application_id: string }>(res);
  assertEquals(body.type, "free");
  assertEquals(body.application_id, "app-old");
  // Should UPDATE, not RPC
  assertEquals(sb.callsFor("event_applications", "update").length, 1);
  assertEquals(sb.callsFor("apply_event", "rpc").length, 0);
  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  assertEquals(patch.status, "approved");
  assertEquals(patch.payment_amount, 0);
});
