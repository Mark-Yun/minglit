/**
 * Tests for withHandler in logger.ts.
 *
 * Verifies core observability regression paths:
 * 1. invoked / completed log entries are emitted on every successful request
 * 2. error log entry is emitted and the exception is re-thrown on handler failure
 *
 * These pin the key behaviour added in #1414 so that future changes cannot
 * silently remove handler-level observability without breaking the test suite.
 */
import { assertEquals } from "@std/assert";
import { stub } from "@std/testing/mock";
import { withHandler, _resetForTesting } from "./logger.ts";
import { _resetForTesting as axiomReset } from "./axiom_logger.ts";

// ---------------------------------------------------------------------------
// Helper: collect console.log / console.error calls during a test
// ---------------------------------------------------------------------------
function collectConsoleLogs(level: "log" | "error"): { messages: string[]; restore: () => void } {
  const messages: string[] = [];
  const s = stub(console, level, (...args: unknown[]) => {
    messages.push(args.map((a) => String(a)).join(" "));
  });
  return { messages, restore: () => s.restore() };
}

Deno.test(
  "withHandler - emits 'invoked' and 'completed' log entries on successful request",
  async () => {
    _resetForTesting();
    axiomReset();

    const { messages, restore } = collectConsoleLogs("log");
    try {
      const handler = withHandler((_req) =>
        Promise.resolve(new Response("ok", { status: 200 }))
      );
      const req = new Request("http://localhost/functions/v1/dev-seed");
      const res = await handler(req);

      assertEquals(res.status, 200);
      assertEquals(
        messages.some((m) => m.includes("invoked")),
        true,
        `Expected an 'invoked' log entry. Got: ${JSON.stringify(messages)}`,
      );
      assertEquals(
        messages.some((m) => m.includes("completed")),
        true,
        `Expected a 'completed' log entry. Got: ${JSON.stringify(messages)}`,
      );
    } finally {
      restore();
    }
  },
);

Deno.test(
  "withHandler - emits 'error' log entry and rethrows when handler throws",
  async () => {
    _resetForTesting();
    axiomReset();

    const { messages, restore } = collectConsoleLogs("error");
    try {
      const handler = withHandler((_req) => {
        throw new Error("boom");
      });
      const req = new Request("http://localhost/functions/v1/dev-seed");

      let threw = false;
      try {
        await handler(req);
      } catch (e) {
        threw = true;
        assertEquals((e as Error).message, "boom");
      }

      assertEquals(threw, true, "Expected handler to rethrow the error");
      assertEquals(
        messages.some((m) => m.includes("boom")),
        true,
        `Expected an error log containing 'boom'. Got: ${JSON.stringify(messages)}`,
      );
    } finally {
      restore();
    }
  },
);
