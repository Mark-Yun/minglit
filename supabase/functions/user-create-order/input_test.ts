import { assertEquals } from "@std/assert";
import { parseCreateOrderInput } from "./input.ts";

async function readError(result: unknown): Promise<{
  status: number;
  body: { error: string };
}> {
  if (!(result instanceof Response)) {
    throw new Error("Expected Response");
  }
  return { status: result.status, body: await result.json() };
}

Deno.test("parseCreateOrderInput accepts required fields", () => {
  assertEquals(
    parseCreateOrderInput({ event_id: "event-1", ticket_id: "ticket-1" }),
    { event_id: "event-1", ticket_id: "ticket-1" },
  );
});

Deno.test("parseCreateOrderInput accepts verification data", () => {
  assertEquals(
    parseCreateOrderInput({
      event_id: "event-1",
      ticket_id: "ticket-1",
      verification_data: {
        verification_id: "verification-1",
        data: { value: true },
      },
    }),
    {
      event_id: "event-1",
      ticket_id: "ticket-1",
      verification_data: {
        verification_id: "verification-1",
        data: { value: true },
      },
    },
  );
});

Deno.test("parseCreateOrderInput preserves stable validation errors", async () => {
  assertEquals(
    await readError(parseCreateOrderInput({ ticket_id: "ticket-1" })),
    {
      status: 400,
      body: { error: "Missing required field: event_id" },
    },
  );
  assertEquals(
    await readError(parseCreateOrderInput({ event_id: "event-1" })),
    {
      status: 400,
      body: { error: "Missing required field: ticket_id" },
    },
  );
  assertEquals(
    await readError(parseCreateOrderInput({
      event_id: "event-1",
      ticket_id: "ticket-1",
      verification_data: { verification_id: "v1", data: [] },
    })),
    {
      status: 400,
      body: { error: "Invalid field: verification_data" },
    },
  );
});
