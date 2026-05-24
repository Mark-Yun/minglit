import { assertEquals } from "@std/assert";
import { parseCancelOrderInput } from "./input.ts";

async function readError(result: unknown): Promise<{
  status: number;
  body: { error: string };
}> {
  if (!(result instanceof Response)) {
    throw new Error("Expected Response");
  }
  return { status: result.status, body: await result.json() };
}

Deno.test("parseCancelOrderInput accepts event id with optional reason", () => {
  assertEquals(parseCancelOrderInput({ event_id: "event-1" }), {
    event_id: "event-1",
  });
  assertEquals(
    parseCancelOrderInput({ event_id: "event-1", reason: "changed" }),
    { event_id: "event-1", reason: "changed" },
  );
});

Deno.test("parseCancelOrderInput preserves validation errors", async () => {
  assertEquals(await readError(parseCancelOrderInput({})), {
    status: 400,
    body: { error: "Missing required field: event_id" },
  });
  assertEquals(
    await readError(parseCancelOrderInput({ event_id: "event-1", reason: 1 })),
    {
      status: 400,
      body: { error: "Invalid field: reason" },
    },
  );
});
