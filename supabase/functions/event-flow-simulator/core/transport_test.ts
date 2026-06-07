import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  createFetchMock,
  withMockedFetch,
} from "../../_test_utils/mock_http.ts";
import { EFTransport } from "./transport.ts";

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
