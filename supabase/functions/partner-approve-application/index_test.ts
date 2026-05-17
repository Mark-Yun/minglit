// partner-approve-application/index_test.ts — handler unit tests (L3, fake supabase)
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

// ─── helpers ───────────────────────────────────────────────────────────────

const VALID_APP_ID = "a1b2c3d4-e5f6-1234-89ab-000000000001";
const VALID_EVENT_ID = "e1b2c3d4-e5f6-1234-89ab-000000000002";
const PARTNER_ID = "p1b2c3d4-e5f6-1234-89ab-000000000003";

/** application row with nested events+parties join (as handler expects). */
function buildAppRow(overrides: { status?: string } = {}) {
  return {
    ...buildApplication({ id: VALID_APP_ID, event_id: VALID_EVENT_ID, status: overrides.status ?? "pending_review" }),
    events: {
      party_id: "party-1",
      parties: { partner_id: PARTNER_ID },
    },
  };
}

/** Script partner_member_permissions as owner (bypasses permission list check). */
function ownerPermScript(sb: ReturnType<typeof fakeSupabase>) {
  return sb.on("partner_member_permissions", "select", {
    data: { role: "owner", permissions: [] },
  });
}

// ─── action routing ────────────────────────────────────────────────────────

Deno.test("partner-approve-application :: missing action field → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, 'Missing or invalid "action" field');
});

Deno.test("partner-approve-application :: unknown action → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { action: "reject" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
});

// ─── approve (single) ──────────────────────────────────────────────────────

Deno.test("partner-approve-application :: approve :: missing application_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { action: "approve" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing application_id");
});

Deno.test("partner-approve-application :: approve :: invalid UUID format → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: "not-a-uuid" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Invalid application_id");
});

Deno.test("partner-approve-application :: approve :: application not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", { data: null });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Application not found");
});

Deno.test("partner-approve-application :: approve :: DB fetch error → 500", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    error: { message: "connection error", code: "08006" },
  });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 500);
});

Deno.test("partner-approve-application :: approve :: partner permission denied (no matching permission) → 403", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow() })
    .on("partner_member_permissions", "select", {
      data: { role: "member", permissions: ["SETTLEMENT_VIEW"] },
    });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 403);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Forbidden: insufficient partner permissions");
});

Deno.test("partner-approve-application :: approve :: non-approvable status (cancelled) → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow({ status: "cancelled" }) })
    .on("partner_member_permissions", "select", {
      data: { role: "owner", permissions: [] },
    });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error.startsWith("Cannot approve application with status"), true);
});

Deno.test("partner-approve-application :: approve :: event_full → 409 EVENT_FULL", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow() });
  ownerPermScript(sb);
  sb.on("approve_event_application_with_capacity_guard", "rpc", {
    data: [{ result_status: "event_full" }],
  });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ details?: { code?: string } }>(res);
  assertEquals(body.details?.code, "EVENT_FULL");
});

Deno.test("partner-approve-application :: approve :: already_processed → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow() });
  ownerPermScript(sb);
  sb.on("approve_event_application_with_capacity_guard", "rpc", {
    data: [{ result_status: "already_processed" }],
  });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 409);
});

Deno.test("partner-approve-application :: approve :: happy path → 200 + approved=1", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow() });
  ownerPermScript(sb);
  sb.on("approve_event_application_with_capacity_guard", "rpc", {
    data: [{ result_status: "approved" }],
  });
  const res = await runHandler(handler, {
    body: { action: "approve", application_id: VALID_APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ approved: number; application_id: string }>(res);
  assertEquals(body.approved, 1);
  assertEquals(body.application_id, VALID_APP_ID);
});

// ─── bulk_approve ──────────────────────────────────────────────────────────

Deno.test("partner-approve-application :: bulk_approve :: missing event_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { action: "bulk_approve" },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing event_id");
});

Deno.test("partner-approve-application :: bulk_approve :: event not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("events", "select", { data: null });
  const res = await runHandler(handler, {
    body: { action: "bulk_approve", event_id: VALID_EVENT_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 404);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Event not found");
});

Deno.test("partner-approve-application :: bulk_approve :: happy path → 200 + approved count", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("events", "select", {
      data: { id: VALID_EVENT_ID, party_id: "party-1", parties: { partner_id: PARTNER_ID } },
    });
  ownerPermScript(sb);
  sb.on("bulk_approve_event_applications_with_capacity_guard", "rpc", {
    data: [{ result_status: "ok", approved_count: 5, skipped_due_to_capacity: 2, remaining_slots_before_approval: 7 }],
  });
  const res = await runHandler(handler, {
    body: { action: "bulk_approve", event_id: VALID_EVENT_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-1" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{
    approved: number;
    event_id: string;
    skipped_due_to_capacity: number;
    remaining_slots_before_approval: number;
  }>(res);
  assertEquals(body.approved, 5);
  assertEquals(body.event_id, VALID_EVENT_ID);
  assertEquals(body.skipped_due_to_capacity, 2);
  assertEquals(body.remaining_slots_before_approval, 7);
});
