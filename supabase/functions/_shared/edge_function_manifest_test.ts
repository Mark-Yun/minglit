// Tests §4.2 actual behavior: manifest entry missing → tryInit() catches throw
// → _initError stored → HTTP 500 on every request. Deploy itself SUCCEEDS.
// This corrects the "deploy fail" claim in docs/architecture/edge-function-auth.md §4.2.
import { assertEquals, assertStringIncludes } from "@std/assert";
import { captureServeHandler, withEnv } from "../_test_utils/mock_http.ts";

const ENV_MISSING_MANIFEST = {
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
  ENVIRONMENT: "dev",
  // "__no_such_ef__" is intentionally absent from auth-manifest.json
  MINGLIT_EF_TEST_FN_NAME: "__no_such_ef__",
};

Deno.test({
  name: "minglitEdgeFunction: missing manifest entry → HTTP 500 on request (deploy succeeds)",
  fn: async () => {
    // Uses cleanup-retention as the EF under test — the EF-specific handler is
    // never reached; only the wrapper's init-error path matters.
    const handler = await captureServeHandler(
      new URL("../cleanup-retention/index.ts", import.meta.url),
    );
    await withEnv(ENV_MISSING_MANIFEST, async () => {
      const res = await handler(
        new Request("http://localhost", { method: "POST" }),
      );
      assertEquals(res.status, 500);
      const body = await res.json() as { error: string };
      assertStringIncludes(body.error, "Init failed:");
      assertStringIncludes(
        body.error,
        "auth-manifest.json missing entry for '__no_such_ef__'",
      );
    });
  },
});
