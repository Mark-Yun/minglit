// partner-reject-application/index_test.ts — handler unit tests (L3, fake supabase)
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

// Shared UUID for valid application_id values
const APP_ID = "11111111-1111-1111-8111-111111111111";
const PARTNER_ID = "22222222-2222-2222-8222-222222222222";

/** Build a fake app row that includes the nested events→parties→partner_id chain. */
function buildAppRow(status: string) {
  return {
    ...buildApplication({ id: APP_ID, status }),
    events: {
      party_id: "party-1",
      parties: {
        partner_id: PARTNER_ID,
      },
    },
  };
}

/** Perm row: owner role → bypasses permission check. */
const OWNER_PERM = { role: "owner", permissions: [] };
/** Perm row: member with APPLICATION_MANAGE permission. */
const MEMBER_PERM = { role: "member", permissions: ["APPLICATION_MANAGE"] };
/** Perm row: member with no useful permissions. */
const NO_PERM = { role: "member", permissions: [] };

// ── 1. Method guard ──────────────────────────────────────────────────────────

Deno.test("partner-reject-application :: GET method → 405", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    method: "GET",
    // No body — GET cannot have a body per Fetch spec
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 405);
});

// ── 2. Input validation ──────────────────────────────────────────────────────

Deno.test("partner-reject-application :: missing application_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing application_id");
});

Deno.test("partner-reject-application :: invalid UUID application_id → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { application_id: "not-a-uuid", reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Invalid application_id");
});

Deno.test("partner-reject-application :: missing reason → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase({ strict: false });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Missing or empty rejection reason");
});

// ── 3. Application fetch branches ───────────────────────────────────────────

Deno.test("partner-reject-application :: application not found → 404", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", { data: null });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 404);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Application not found");
});

Deno.test("partner-reject-application :: DB error on fetch → 500", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    error: { message: "connection timeout", code: "08000" },
  });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 500);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Failed to load application");
});

// ── 4. Status guard ──────────────────────────────────────────────────────────

Deno.test("partner-reject-application :: status=paid (non-rejectable) → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildAppRow("paid"),
  });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "No slots" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 400);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error.startsWith("Cannot reject application with status"), true);
});

Deno.test("partner-reject-application :: status=rejected (already rejected) → 400", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase().on("event_applications", "select", {
    data: buildAppRow("rejected"),
  });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "Duplicate" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 400);
});

// ── 5. Permission check ──────────────────────────────────────────────────────

Deno.test("partner-reject-application :: insufficient permissions → 403", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow("pending") })
    .on("partner_member_permissions", "select", { data: NO_PERM });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-member" }),
  });
  assertEquals(res.status, 403);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Forbidden: insufficient partner permissions");
});

// ── 6. Concurrent update race (409) ─────────────────────────────────────────

Deno.test("partner-reject-application :: concurrent update (empty rows) → 409", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow("pending") })
    .on("partner_member_permissions", "select", { data: OWNER_PERM })
    .on("event_applications", "update", { data: [] }); // 0 rows → status changed concurrently
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 409);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Application already processed");
});

// ── 7. DB error on update ────────────────────────────────────────────────────

Deno.test("partner-reject-application :: DB error on update → 500", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow("pending") })
    .on("partner_member_permissions", "select", { data: OWNER_PERM })
    .on("event_applications", "update", { error: { message: "deadlock", code: "40P01" } });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "Not a fit" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 500);
  const body = await readJson<{ error: string }>(res);
  assertEquals(body.error, "Failed to reject application");
});

// ── 8. Success paths ─────────────────────────────────────────────────────────

Deno.test("partner-reject-application :: status=pending + owner role → 200", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow("pending") })
    .on("partner_member_permissions", "select", { data: OWNER_PERM })
    .on("event_applications", "update", { data: [{ id: APP_ID }] });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "No available slots" },
    ctx: makeCtx({ supabase: sb, userId: "u-partner" }),
  });
  assertEquals(res.status, 200);
  const body = await readJson<{ rejected: number; application_id: string }>(res);
  assertEquals(body.rejected, 1);
  assertEquals(body.application_id, APP_ID);

  // Verify update payload sets status=rejected with trimmed reason
  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  assertEquals(patch.status, "rejected");
  assertEquals(patch.rejection_reason, "No available slots");
});

Deno.test("partner-reject-application :: status=pending_review + member with APPLICATION_MANAGE → 200", async () => {
  const handler = await getHandler();
  const sb = fakeSupabase()
    .on("event_applications", "select", { data: buildAppRow("pending_review") })
    .on("partner_member_permissions", "select", { data: MEMBER_PERM })
    .on("event_applications", "update", { data: [{ id: APP_ID }] });
  const res = await runHandler(handler, {
    body: { application_id: APP_ID, reason: "  does not meet requirements  " },
    ctx: makeCtx({ supabase: sb, userId: "u-member" }),
  });
  assertEquals(res.status, 200);

  // Reason should be trimmed
  const [updateCall] = sb.callsFor("event_applications", "update");
  const patch = updateCall.payload as Record<string, unknown>;
  assertEquals(patch.status, "rejected");
  assertEquals(patch.rejection_reason, "does not meet requirements");
});
