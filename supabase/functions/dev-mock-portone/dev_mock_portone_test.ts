import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  readJson,
  withEnv,
} from "../_test_utils/mock_http.ts";

Deno.test({
  name: "dev-mock-portone - blocks in production (ENVIRONMENT=production)",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({ ENVIRONMENT: "production" }, async () => {
      const response = await handler(new Request("http://localhost/users/getToken", { method: "POST" }));
      assertEquals(response.status, 403);
      const body = await readJson(response);
      assertEquals(body.error, "Dev-only function. Blocked in production.");
    });
  },
});

Deno.test({
  name: "dev-mock-portone - POST /users/getToken returns mock token",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({ ENVIRONMENT: "local" }, async () => {
      const response = await handler(
        new Request("http://localhost/users/getToken", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ imp_key: "test-key", imp_secret: "test-secret" }),
        }),
      );
      assertEquals(response.status, 200);
      const body = await readJson(response);
      assertEquals(body.code, 0);
      assertEquals(body.response.access_token, "mock-token-for-testing");
    });
  },
});

Deno.test({
  name: "dev-mock-portone - GET /payments/:imp_uid returns paid payment",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({ ENVIRONMENT: "development" }, async () => {
      const response = await handler(
        new Request("http://localhost/payments/imp_test_123", {
          method: "GET",
          headers: { "Authorization": "Bearer mock-token-for-testing" },
        }),
      );
      assertEquals(response.status, 200);
      const body = await readJson(response);
      assertEquals(body.code, 0);
      assertEquals(body.response.status, "paid");
      assertEquals(body.response.amount, 15000);
      assertEquals(body.response.merchant_uid, "order-test-123");
      assertEquals(body.response.imp_uid, "imp_test_123");
    });
  },
});

Deno.test({
  name: "dev-mock-portone - GET /payments/imp_fail_xxx returns failed status",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({ ENVIRONMENT: "local" }, async () => {
      const response = await handler(
        new Request("http://localhost/payments/imp_fail_abc", {
          method: "GET",
          headers: { "Authorization": "Bearer mock-token-for-testing" },
        }),
      );
      assertEquals(response.status, 200);
      const body = await readJson(response);
      assertEquals(body.code, 0);
      assertEquals(body.response.status, "failed");
    });
  },
});

Deno.test({
  name: "dev-mock-portone - POST /payments/cancel returns cancelled response",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({ ENVIRONMENT: "local" }, async () => {
      const response = await handler(
        new Request("http://localhost/payments/cancel", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer mock-token-for-testing",
          },
          body: JSON.stringify({ imp_uid: "imp_test_456", reason: "test cancel" }),
        }),
      );
      assertEquals(response.status, 200);
      const body = await readJson(response);
      assertEquals(body.code, 0);
      assertEquals(body.response.imp_uid, "imp_test_456");
      assertEquals(body.response.status, "cancelled");
      assertEquals(body.response.cancel_amount, 15000);
    });
  },
});

Deno.test({
  name: "dev-mock-portone - unknown path returns 404",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    await withEnv({ ENVIRONMENT: "local" }, async () => {
      const response = await handler(
        new Request("http://localhost/unknown/path", { method: "GET" }),
      );
      assertEquals(response.status, 404);
      const body = await readJson(response);
      assertEquals(body.error, "Not found");
    });
  },
});
