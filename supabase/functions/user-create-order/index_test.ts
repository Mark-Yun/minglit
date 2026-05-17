// user-create-order/index_test.ts — handler unit tests (L3, fake supabase)

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildApplication,
  buildEvent,
  buildTicket,
  buildUserProfile,
  fakeSupabase,
  makeCtx,
  readJson,
  runHandler,
} from "../_shared/_testing/mod.ts";
import { handler } from "./index.ts";

// ── helpers ────────────────────────────────────────────────────────────────────

/** Build the minimal fake required for a happy-path (no entry groups, no existing app). */
function happyPathFake(overrides: {
  event?: Partial<Parameters<typeof buildEvent>[0]>;
  ticket?: Partial<Parameters<typeof buildTicket>[0]>;
  profile?: Partial<Parameters<typeof buildUserProfile>[0]>;
} = {}) {
  return fakeSupabase()
    .on("events", "select", { data: buildEvent(overrides.event) })
    .on("tickets", "select", { data: buildTicket(overrides.ticket) })
    .on("user_profiles", "select", { data: buildUserProfile(overrides.profile) })
    .on("check_party_balance", "rpc", { data: { allowed: true } })
    .on("event_applications", "select", { error: { message: "no rows", code: "PGRST116" } })
    .on("apply_event", "rpc", { data: "app-new-1" })
    .on("event_applications", "update", { error: null });
}

// ── input validation ───────────────────────────────────────────────────────────

Deno.test("user-create-order :: missing event_id → 400", async () => {
  const sb = fakeSupabase();
  const res = await runHandler(handler, {
    body: { ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error.toLowerCase().includes("event_id"), true);
});

Deno.test("user-create-order :: missing ticket_id → 400", async () => {
  const sb = fakeSupabase();
  const res = await runHandler(handler, {
    body: { event_id: "ev-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error.toLowerCase().includes("ticket_id"), true);
});

// ── event checks ───────────────────────────────────────────────────────────────

Deno.test("user-create-order :: event not found → 404", async () => {
  const sb = fakeSupabase().on("events", "select", {
    error: { message: "no rows", code: "PGRST116" },
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

Deno.test("user-create-order :: event status=cancelled → 400 EVENT_CLOSED", async () => {
  const sb = fakeSupabase().on("events", "select", {
    data: buildEvent({ status: "cancelled" }),
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "EVENT_CLOSED");
});

Deno.test("user-create-order :: event already started → 400 EVENT_NOT_SCHEDULED", async () => {
  const sb = fakeSupabase().on("events", "select", {
    data: buildEvent({ status: "scheduled", start_time: "2020-01-01T00:00:00Z" }),
  });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "EVENT_NOT_SCHEDULED");
});

// ── ticket checks ──────────────────────────────────────────────────────────────

Deno.test("user-create-order :: ticket not found → 404", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { error: { message: "no rows", code: "PGRST116" } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

Deno.test("user-create-order :: ticket belongs to different event → 404", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent({ id: "ev-1" }) })
    .on("tickets", "select", { data: buildTicket({ event_id: "ev-OTHER" }) });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

Deno.test("user-create-order :: ticket sold out → 400 TICKET_SOLD_OUT", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket({ sold_count: 30, quantity: 30 }) });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "TICKET_SOLD_OUT");
});

Deno.test("user-create-order :: event full → 400 EVENT_FULL", async () => {
  const sb = fakeSupabase()
    .on("events", "select", {
      data: buildEvent({ current_participants: 30, max_participants: 30 }),
    })
    .on("tickets", "select", { data: buildTicket() });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "EVENT_FULL");
});

// ── user profile / identity ────────────────────────────────────────────────────

Deno.test("user-create-order :: user profile not found → 404", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("user_profiles", "select", { error: { message: "no rows", code: "PGRST116" } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
});

Deno.test("user-create-order :: user not verified → 400 IDENTITY_REQUIRED", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("user_profiles", "select", { data: buildUserProfile({ is_verified: false }) });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "IDENTITY_REQUIRED");
});

// ── duplicate application ──────────────────────────────────────────────────────

Deno.test("user-create-order :: existing application (paid) → 400 ALREADY_APPLIED", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("user_profiles", "select", { data: buildUserProfile() })
    .on("check_party_balance", "rpc", { data: { allowed: true } })
    .on("event_applications", "select", {
      data: buildApplication({ status: "paid" }),
    });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "ALREADY_APPLIED");
});

Deno.test("user-create-order :: existing application (cancelled) → reapplication allowed, 200", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("user_profiles", "select", { data: buildUserProfile() })
    .on("check_party_balance", "rpc", { data: { allowed: true } })
    .on("event_applications", "select", {
      data: buildApplication({ status: "cancelled" }),
    })
    .on("apply_event", "rpc", { data: "app-reused-1" })
    .on("event_applications", "update", { error: null });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ success: boolean; application_id: string }>(res);
  assertEquals(body.success, true);
  assertEquals(body.application_id, "app-reused-1");
  // update path for existing app was taken
  assertEquals(sb.callsFor("event_applications", "update").length, 1);
});

// ── happy paths ────────────────────────────────────────────────────────────────

Deno.test("user-create-order :: paid ticket — happy path → 200 + requires_payment=true", async () => {
  const sb = happyPathFake({ ticket: { price: 15000 } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{
    success: boolean;
    application_id: string;
    amount: number;
    requires_payment: boolean;
    ticket_name: string;
  }>(res);
  assertEquals(body.success, true);
  assertEquals(body.requires_payment, true);
  assertEquals(body.amount, 15000);
  assertEquals(body.ticket_name, "General");
  assertEquals(body.application_id, "app-new-1");
});

Deno.test("user-create-order :: free ticket (price=0) — happy path → 200 + requires_payment=false", async () => {
  const sb = happyPathFake({ ticket: { price: 0 } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{
    success: boolean;
    requires_payment: boolean;
    amount: number;
  }>(res);
  assertEquals(body.success, true);
  assertEquals(body.requires_payment, false);
  assertEquals(body.amount, 0);
});

Deno.test("user-create-order :: party balance blocked → 400 BALANCE_LIMIT", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("user_profiles", "select", { data: buildUserProfile() })
    .on("check_party_balance", "rpc", { data: { allowed: false } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "BALANCE_LIMIT");
});

Deno.test("user-create-order :: apply_event RPC error → 500", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: buildEvent() })
    .on("tickets", "select", { data: buildTicket() })
    .on("user_profiles", "select", { data: buildUserProfile() })
    .on("check_party_balance", "rpc", { data: { allowed: true } })
    .on("event_applications", "select", { error: { message: "no rows", code: "PGRST116" } })
    .on("apply_event", "rpc", { error: { message: "constraint violation", code: "23505" } });
  const res = await runHandler(handler, {
    body: { event_id: "ev-1", ticket_id: "tk-1" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 500);
});
