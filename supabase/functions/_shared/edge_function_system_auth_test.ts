import { assertEquals, assertInstanceOf } from "@std/assert";
import { checkSystemAuth, type EFPolicy, verifyAuth } from "./edge_function.ts";
import { withEnv } from "../_test_utils/mock_http.ts";

const SYSTEM_POLICY: EFPolicy = {
  callers: ["system"],
  envs: ["dev"],
};

const AUTH_ENV = {
  SUPABASE_SERVICE_ROLE_KEY: "legacy-service-role-jwt",
  SUPABASE_SERVICE_ROLE_SECRET: "sb_secret_test_secret_key",
};

function request(headers: Record<string, string> = {}): Request {
  return new Request("http://localhost", { method: "POST", headers });
}

async function expectUnauthorized(req: Request): Promise<void> {
  const result = await verifyAuth(req, SYSTEM_POLICY, "test-system-fn");
  assertInstanceOf(result, Response);
  assertEquals(result.status, 401);
}

Deno.test("checkSystemAuth: legacy bearer service_role key passes as legacy", async () => {
  await withEnv(AUTH_ENV, () => {
    const result = checkSystemAuth(request({
      Authorization: "Bearer legacy-service-role-jwt",
    }));
    assertEquals(result, { ok: true, keyFormat: "legacy" });
  });
});

Deno.test("checkSystemAuth: sb_secret apikey passes as secret", async () => {
  await withEnv(AUTH_ENV, () => {
    const result = checkSystemAuth(request({
      apikey: "sb_secret_test_secret_key",
    }));
    assertEquals(result, { ok: true, keyFormat: "secret" });
  });
});

Deno.test("verifyAuth: missing system credentials returns 401", async () => {
  await withEnv(AUTH_ENV, async () => {
    await expectUnauthorized(request());
  });
});

Deno.test("verifyAuth: wrong bearer returns 401", async () => {
  await withEnv(AUTH_ENV, async () => {
    await expectUnauthorized(request({
      Authorization: "Bearer wrong-key",
    }));
  });
});

Deno.test("verifyAuth: wrong apikey returns 401", async () => {
  await withEnv(AUTH_ENV, async () => {
    await expectUnauthorized(request({
      apikey: "sb_secret_wrong_key",
    }));
  });
});

Deno.test("verifyAuth: user JWT bearer does not pass a system-only policy", async () => {
  await withEnv(AUTH_ENV, async () => {
    await expectUnauthorized(request({
      Authorization: "Bearer user-jwt-token",
    }));
  });
});

Deno.test("verifyAuth: Authorization bearer sb_secret is not accepted", async () => {
  await withEnv(AUTH_ENV, async () => {
    await expectUnauthorized(request({
      Authorization: "Bearer sb_secret_test_secret_key",
    }));
  });
});

Deno.test("verifyAuth: secret apikey system caller passes without Authorization", async () => {
  await withEnv(AUTH_ENV, async () => {
    const result = await verifyAuth(
      request({ apikey: "sb_secret_test_secret_key" }),
      SYSTEM_POLICY,
      "test-system-fn",
    );
    assertEquals(result, { type: "system", keyFormat: "secret" });
  });
});

Deno.test("verifyAuth: legacy bearer system caller still passes", async () => {
  await withEnv(AUTH_ENV, async () => {
    const result = await verifyAuth(
      request({ Authorization: "Bearer legacy-service-role-jwt" }),
      SYSTEM_POLICY,
      "test-system-fn",
    );
    assertEquals(result, { type: "system", keyFormat: "legacy" });
  });
});

Deno.test("verifyAuth: missing SUPABASE_SERVICE_ROLE_SECRET fails closed for apikey", async () => {
  await withEnv(
    { ...AUTH_ENV, SUPABASE_SERVICE_ROLE_SECRET: undefined },
    async () => {
      await expectUnauthorized(request({
        apikey: "sb_secret_test_secret_key",
      }));
    },
  );
});
