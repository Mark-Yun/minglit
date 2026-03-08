import { assertEquals } from "@std/assert";
import { successResponse, errorResponse } from "./response_utils.ts";

Deno.test("successResponse - returns JSON with status 200 by default", async () => {
  const response = successResponse({ message: "ok" });

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("Content-Type"), "application/json");

  const body = await response.json();
  assertEquals(body.message, "ok");
});

Deno.test("successResponse - uses custom status code", async () => {
  const response = successResponse({ created: true }, 201);

  assertEquals(response.status, 201);
});

Deno.test("errorResponse - returns JSON with error message and status 400 by default", async () => {
  const response = errorResponse("Something went wrong");

  assertEquals(response.status, 400);
  assertEquals(response.headers.get("Content-Type"), "application/json");

  const body = await response.json();
  assertEquals(body.error, "Something went wrong");
});

Deno.test("errorResponse - uses custom status code", async () => {
  const response = errorResponse("Not found", 404);

  assertEquals(response.status, 404);
});

Deno.test("errorResponse - includes details when provided", async () => {
  const response = errorResponse("Validation failed", 422, { field: "email" });

  const body = await response.json();
  assertEquals(body.error, "Validation failed");
  assertEquals(body.details.field, "email");
});

Deno.test("errorResponse - excludes details when not provided", async () => {
  const response = errorResponse("Error");

  const body = await response.json();
  assertEquals(body.error, "Error");
  assertEquals(body.details, undefined);
});
