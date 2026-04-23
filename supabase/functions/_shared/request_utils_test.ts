import { assertEquals } from "@std/assert";
import { parseJsonBody, parseAction } from "./request_utils.ts";

// parseJsonBody

Deno.test("parseJsonBody - valid object → returns parsed body", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ foo: "bar" }),
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseJsonBody(req);
  assertEquals(result instanceof Response, false);
  assertEquals((result as Record<string, unknown>).foo, "bar");
});

Deno.test("parseJsonBody - invalid JSON → 400 Invalid JSON body", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: "not-json",
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseJsonBody(req);
  assertEquals(result instanceof Response, true);
  assertEquals((result as Response).status, 400);
  const body = await (result as Response).json();
  assertEquals(body.error, "Invalid JSON body");
});

Deno.test("parseJsonBody - null body → 400 Request body must be a JSON object", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: "null",
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseJsonBody(req);
  assertEquals(result instanceof Response, true);
  assertEquals((result as Response).status, 400);
  const body = await (result as Response).json();
  assertEquals(body.error, "Request body must be a JSON object");
});

Deno.test("parseJsonBody - array body → 400 Request body must be a JSON object", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify([1, 2, 3]),
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseJsonBody(req);
  assertEquals(result instanceof Response, true);
  assertEquals((result as Response).status, 400);
  const body = await (result as Response).json();
  assertEquals(body.error, "Request body must be a JSON object");
});

// parseAction

Deno.test("parseAction - valid action → returns { action, body }", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ action: "create", data: 42 }),
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseAction(req);
  assertEquals(result instanceof Response, false);
  const r = result as { action: string; body: Record<string, unknown> };
  assertEquals(r.action, "create");
  assertEquals(r.body.data, 42);
});

Deno.test("parseAction - action field missing → 400 Missing or invalid action field", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ data: "no-action" }),
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseAction(req);
  assertEquals(result instanceof Response, true);
  assertEquals((result as Response).status, 400);
  const body = await (result as Response).json();
  assertEquals(body.error, 'Missing or invalid "action" field');
});

Deno.test("parseAction - action is number → 400 Missing or invalid action field", async () => {
  const req = new Request("http://localhost", {
    method: "POST",
    body: JSON.stringify({ action: 123 }),
    headers: { "Content-Type": "application/json" },
  });
  const result = await parseAction(req);
  assertEquals(result instanceof Response, true);
  assertEquals((result as Response).status, 400);
  const body = await (result as Response).json();
  assertEquals(body.error, 'Missing or invalid "action" field');
});
