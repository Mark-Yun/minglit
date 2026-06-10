import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  createFetchMock,
  withMockedFetch,
} from "../../_test_utils/mock_http.ts";
import { EFTransport } from "./transport.ts";

Deno.test("EFTransport returns failure when actor token is missing", async () => {
  const transport = new EFTransport({
    supabase: {} as SupabaseClient,
    supabaseUrl: "https://example.supabase.co",
    tokenByActor: new Map(),
    runId: "run-1",
  });

  const result = await transport.execute({
    type: "user_apply",
    actorId: "user-1",
    ef: "apply-event",
    payload: { event_id: "event-1", ticket_id: "ticket-1" },
  });

  assertEquals(result, {
    ok: false,
    status: 0,
    error: "no token for actor user-1",
  });
});

Deno.test("EFTransport adds Idempotency-Key for apply-event calls", async () => {
  let idempotencyKey: string | null = null;
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: (req) => {
        assertEquals(req.headers.get("Authorization"), "Bearer test-token");
        idempotencyKey = req.headers.get("Idempotency-Key");
        return Response.json({ success: true });
      },
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result.ok, true);
    assertEquals(result.status, 200);
  });

  assertEquals(
    idempotencyKey,
    "event-flow-simulator:run-1:0:user_apply",
  );
});

Deno.test("EFTransport omits Idempotency-Key for functions without that contract", async () => {
  let idempotencyKey: string | null = "unexpected";
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/event-checkin"),
      handler: (req) => {
        idempotencyKey = req.headers.get("Idempotency-Key");
        return Response.json({ success: true });
      },
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
    });

    await transport.execute({
      type: "user_checkin",
      actorId: "user-1",
      ef: "event-checkin",
      payload: { event_id: "event-1" },
    });
  });

  assertEquals(idempotencyKey, null);
});

Deno.test("EFTransport includes error body for failed Edge Function calls", async () => {
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () =>
        Response.json(
          { error: "Event is not accepting applications" },
          { status: 409 },
        ),
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result.ok, false);
    assertEquals(result.status, 409);
    assertEquals(result.error, "Event is not accepting applications");
  });
});

Deno.test("EFTransport retries transient Edge Function load failures", async () => {
  let calls = 0;
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () => {
        calls++;
        if (calls === 1) {
          return Response.json(
            { message: "Failed to load edge function" },
            { status: 503 },
          );
        }
        return Response.json({ type: "free", application_id: "app-1" });
      },
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
      edgeLoadRetryDelaysMs: [0],
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result, {
      ok: true,
      status: 200,
      data: { type: "free", application_id: "app-1" },
      error: undefined,
    });
  });

  assertEquals(calls, 2);
});

Deno.test("EFTransport does not retry non-load 503 failures", async () => {
  let calls = 0;
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () => {
        calls++;
        return Response.json(
          { error: "Service unavailable" },
          { status: 503 },
        );
      },
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
      edgeLoadRetryDelaysMs: [0, 0],
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result.ok, false);
    assertEquals(result.status, 503);
    assertEquals(result.error, "Service unavailable");
  });

  assertEquals(calls, 1);
});

Deno.test("EFTransport preserves final Edge Function load failure after retries", async () => {
  let calls = 0;
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () => {
        calls++;
        return Response.json(
          { error: "Failed to load edge function" },
          { status: 503 },
        );
      },
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
      edgeLoadRetryDelaysMs: [0, 0],
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result.ok, false);
    assertEquals(result.status, 503);
    assertEquals(result.error, "Failed to load edge function");
  });

  assertEquals(calls, 3);
});

Deno.test("EFTransport treats already-applied apply conflicts as benign", async () => {
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () =>
        Response.json(
          { error: "Already applied to this event" },
          { status: 409 },
        ),
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result, {
      ok: true,
      status: 409,
      data: { type: "already_applied" },
    });
  });
});

Deno.test("EFTransport preserves string error bodies for failed Edge Function calls", async () => {
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () => Response.json("ticket sold out", { status: 409 }),
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result.ok, false);
    assertEquals(result.status, 409);
    assertEquals(result.error, "ticket sold out");
  });
});

Deno.test("EFTransport leaves error empty when failed response body has no message", async () => {
  const { fetchMock } = createFetchMock([
    {
      matcher: (req) => req.url.endsWith("/functions/v1/apply-event"),
      handler: () => new Response(null, { status: 500 }),
    },
  ]);

  await withMockedFetch(fetchMock, async () => {
    const transport = new EFTransport({
      supabase: {} as SupabaseClient,
      supabaseUrl: "https://example.supabase.co",
      tokenByActor: new Map([["user-1", "test-token"]]),
      runId: "run-1",
    });

    const result = await transport.execute({
      type: "user_apply",
      actorId: "user-1",
      ef: "apply-event",
      payload: { event_id: "event-1", ticket_id: "ticket-1" },
    });

    assertEquals(result.ok, false);
    assertEquals(result.status, 500);
    assertEquals(result.error, undefined);
  });
});
