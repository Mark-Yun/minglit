import { assertEquals } from "@std/assert";
import { parsePaymentVerifyInput } from "./input.ts";

async function readError(result: unknown): Promise<{
  status: number;
  body: { error: string };
}> {
  if (!(result instanceof Response)) {
    throw new Error("Expected Response");
  }
  return { status: result.status, body: await result.json() };
}

Deno.test("parsePaymentVerifyInput accepts payment IDs", () => {
  assertEquals(
    parsePaymentVerifyInput({ imp_uid: "imp-1", merchant_uid: "order-1" }),
    { imp_uid: "imp-1", merchant_uid: "order-1" },
  );
});

Deno.test("parsePaymentVerifyInput preserves missing parameter response", async () => {
  assertEquals(
    await readError(parsePaymentVerifyInput({ merchant_uid: "order-1" })),
    {
      status: 400,
      body: { error: "Missing required parameters" },
    },
  );
  assertEquals(await readError(parsePaymentVerifyInput({ imp_uid: "imp-1" })), {
    status: 400,
    body: { error: "Missing required parameters" },
  });
});
