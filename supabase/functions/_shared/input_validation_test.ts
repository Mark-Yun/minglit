import { assertEquals } from "@std/assert";
import {
  isPlainRecord,
  optionalStringField,
  requireStringField,
  requireUuidField,
} from "./input_validation.ts";

async function readError(result: unknown): Promise<{
  status: number;
  body: { error: string };
}> {
  if (!(result instanceof Response)) {
    throw new Error("Expected Response");
  }
  return { status: result.status, body: await result.json() };
}

Deno.test("isPlainRecord accepts objects only", () => {
  assertEquals(isPlainRecord({}), true);
  assertEquals(isPlainRecord({ value: 1 }), true);
  assertEquals(isPlainRecord(null), false);
  assertEquals(isPlainRecord([]), false);
  assertEquals(isPlainRecord("x"), false);
});

Deno.test("requireStringField returns non-empty string", () => {
  assertEquals(
    requireStringField({ event_id: "event-1" }, "event_id"),
    "event-1",
  );
});

Deno.test("requireStringField returns stable 400 response", async () => {
  assertEquals(
    await readError(requireStringField({}, "event_id")),
    {
      status: 400,
      body: { error: "Missing required field: event_id" },
    },
  );
  assertEquals(
    await readError(
      requireStringField({ event_id: "" }, "event_id", "Missing"),
    ),
    {
      status: 400,
      body: { error: "Missing" },
    },
  );
});

Deno.test("optionalStringField accepts missing or string only", async () => {
  assertEquals(optionalStringField({}, "reason"), undefined);
  assertEquals(optionalStringField({ reason: "changed" }, "reason"), "changed");
  assertEquals(
    await readError(optionalStringField({ reason: 1 }, "reason")),
    {
      status: 400,
      body: { error: "Invalid field: reason" },
    },
  );
});

Deno.test("requireUuidField validates required UUID fields", async () => {
  const uuid = "123e4567-e89b-12d3-a456-426614174000";
  const messages = { missing: "Missing id", invalid: "Invalid id" };

  assertEquals(requireUuidField({ id: uuid }, "id", messages), uuid);
  assertEquals(await readError(requireUuidField({}, "id", messages)), {
    status: 400,
    body: { error: "Missing id" },
  });
  assertEquals(
    await readError(requireUuidField({ id: "not-uuid" }, "id", messages)),
    {
      status: 400,
      body: { error: "Invalid id" },
    },
  );
});
