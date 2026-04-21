import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  withEnv,
} from "../_test_utils/mock_http.ts";

const BASE_ENV = {
  SUPABASE_URL: "https://test.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

// ---------------------------------------------------------------------------
// Smoke tests — verifies the handler returns valid JSON in all paths.
// Full integration tests require a live Supabase instance with admin schema.
// sanitizeResources/sanitizeOps disabled because supabase-js creates background
// intervals for auth token management when createClient() is called.
// ---------------------------------------------------------------------------

Deno.test({
  name: "cleanup-retention - returns JSON response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(BASE_ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      // The handler will fail to fetch policies from Supabase (no live DB),
      // but it must still return a JSON response (either results or error).
      const response = await handler(
        new Request("http://localhost", { method: "POST" }),
      );

      assertEquals(response.headers.get("content-type"), "application/json");
      const body = await response.json();
      assertEquals(typeof body, "object");
    });
  },
});

Deno.test({
  name: "cleanup-retention - response has expected shape on error",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(BASE_ENV, async () => {
      const handler = await captureServeHandler(
        new URL("./index.ts", import.meta.url),
      );

      const response = await handler(
        new Request("http://localhost", { method: "POST" }),
      );

      const body = await response.json();
      // Either a success shape { total_duration_ms, results } or error shape { error }
      const isSuccess = "total_duration_ms" in body && "results" in body;
      const isError = "error" in body;
      assertEquals(isSuccess || isError, true);
    });
  },
});
