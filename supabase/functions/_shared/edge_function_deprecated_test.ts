// Tests for manifest `deprecated` field — RFC 8594 Deprecation + Sunset headers (#2188)
import { assertEquals } from "@std/assert";
import { addDeprecationHeaders } from "./edge_function.ts";

function okResponse(body = "ok"): Response {
  return new Response(body, { status: 200 });
}

Deno.test("addDeprecationHeaders: adds Deprecation header in @<HTTP-date> format", () => {
  const res = addDeprecationHeaders(okResponse(), "2026-12-01");
  const deprecation = res.headers.get("Deprecation");
  const expected = new Date("2026-12-01").toUTCString();
  assertEquals(deprecation, `@${expected}`);
});

Deno.test("addDeprecationHeaders: adds Sunset header as HTTP-date", () => {
  const res = addDeprecationHeaders(okResponse(), "2026-12-01");
  const sunset = res.headers.get("Sunset");
  const expected = new Date("2026-12-01").toUTCString();
  assertEquals(sunset, expected);
});

Deno.test("addDeprecationHeaders: preserves original status and body", async () => {
  const original = new Response("hello", { status: 201 });
  const res = addDeprecationHeaders(original, "2026-06-30");
  assertEquals(res.status, 201);
  assertEquals(await res.text(), "hello");
});

Deno.test("addDeprecationHeaders: preserves existing response headers", () => {
  const original = new Response("ok", {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
  const res = addDeprecationHeaders(original, "2026-12-01");
  assertEquals(res.headers.get("Content-Type"), "application/json");
  assertEquals(res.headers.has("Deprecation"), true);
  assertEquals(res.headers.has("Sunset"), true);
});

Deno.test("addDeprecationHeaders: Deprecation and Sunset reference the same date", () => {
  const res = addDeprecationHeaders(okResponse(), "2027-03-15");
  const deprecation = res.headers.get("Deprecation") ?? "";
  const sunset = res.headers.get("Sunset") ?? "";
  // Deprecation is "@<sunset>", so removing "@" prefix should equal Sunset
  assertEquals(deprecation, `@${sunset}`);
});

Deno.test("addDeprecationHeaders: returns original response unchanged for invalid date", () => {
  const original = okResponse();
  const res = addDeprecationHeaders(original, "not-a-date");
  assertEquals(res.headers.has("Deprecation"), false);
  assertEquals(res.headers.has("Sunset"), false);
});
