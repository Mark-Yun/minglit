import { assertEquals } from "@std/assert";
import { log, flush, extractFunctionName, isEnabled, _resetForTesting, _getBuffer } from "./axiom_logger.ts";

Deno.test("log - buffers event only when enabled", () => {
  _resetForTesting();
  log({ function: "payment-verify", level: "info", message: "started" });

  const buffer = _getBuffer();
  if (isEnabled()) {
    assertEquals(buffer.length, 1);
    assertEquals(buffer[0].function, "payment-verify");
    assertEquals(buffer[0].level, "info");
    assertEquals(buffer[0].message, "started");
  } else {
    assertEquals(buffer.length, 0);
  }
});

Deno.test("log - includes metadata when provided", () => {
  _resetForTesting();
  log({ function: "payment-verify", level: "info", message: "ok", metadata: { amount: 50000 } });

  const buffer = _getBuffer();
  if (isEnabled()) {
    assertEquals(buffer[0].metadata?.amount, 50000);
  }
});

Deno.test("log - omits metadata field when not provided", () => {
  _resetForTesting();
  log({ function: "health", level: "info", message: "ok" });

  const buffer = _getBuffer();
  if (isEnabled()) {
    assertEquals(buffer[0].metadata, undefined);
  }
});

Deno.test("flush - no-ops when disabled (no token)", async () => {
  _resetForTesting();
  log({ function: "test", level: "info", message: "hello" });

  if (!isEnabled()) {
    assertEquals(_getBuffer().length, 0);
  } else {
    assertEquals(_getBuffer().length, 1);
  }

  await flush();

  assertEquals(_getBuffer().length, 0);
});

Deno.test("flush - resets buffer for testing", () => {
  _resetForTesting();
  log({ function: "test", level: "info", message: "a" });
  log({ function: "test", level: "error", message: "b" });

  if (isEnabled()) {
    assertEquals(_getBuffer().length, 2);
  } else {
    assertEquals(_getBuffer().length, 0);
  }

  _resetForTesting();
  assertEquals(_getBuffer().length, 0);
});

Deno.test("extractFunctionName - parses supabase URL", () => {
  const req = new Request("https://abc.supabase.co/functions/v1/payment-verify");
  assertEquals(extractFunctionName(req), "payment-verify");
});

Deno.test("extractFunctionName - parses localhost URL", () => {
  const req = new Request("http://127.0.0.1:54321/functions/v1/notification-worker");
  assertEquals(extractFunctionName(req), "notification-worker");
});

Deno.test("extractFunctionName - falls back to last segment", () => {
  const req = new Request("http://localhost/some/unknown/path");
  assertEquals(extractFunctionName(req), "path");
});

Deno.test("extractFunctionName - returns unknown for invalid URL", () => {
  const req = { url: "not-a-url" } as Request;
  assertEquals(extractFunctionName(req), "unknown");
});
