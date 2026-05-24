import { assertEquals } from "@std/assert";
import { parsePartnerApproveInput } from "./input.ts";

const UUID = "123e4567-e89b-12d3-a456-426614174000";

async function readError(result: unknown): Promise<{
  status: number;
  body: { error: string };
}> {
  if (!(result instanceof Response)) {
    throw new Error("Expected Response");
  }
  return { status: result.status, body: await result.json() };
}

Deno.test("parsePartnerApproveInput accepts approve action", () => {
  assertEquals(
    parsePartnerApproveInput("approve", { application_id: UUID }),
    { action: "approve", applicationId: UUID },
  );
});

Deno.test("parsePartnerApproveInput accepts bulk approve action", () => {
  assertEquals(
    parsePartnerApproveInput("bulk_approve", { event_id: UUID }),
    { action: "bulk_approve", eventId: UUID },
  );
});

Deno.test("parsePartnerApproveInput preserves stable validation errors", async () => {
  assertEquals(await readError(parsePartnerApproveInput("approve", {})), {
    status: 400,
    body: { error: "Missing application_id" },
  });
  assertEquals(
    await readError(
      parsePartnerApproveInput("approve", { application_id: "x" }),
    ),
    {
      status: 400,
      body: { error: "Invalid application_id" },
    },
  );
  assertEquals(await readError(parsePartnerApproveInput("bulk_approve", {})), {
    status: 400,
    body: { error: "Missing event_id" },
  });
  assertEquals(
    await readError(
      parsePartnerApproveInput("bulk_approve", { event_id: "x" }),
    ),
    {
      status: 400,
      body: { error: "Invalid event_id" },
    },
  );
  assertEquals(await readError(parsePartnerApproveInput("noop", {})), {
    status: 400,
    body: { error: "Unknown action: noop" },
  });
});
