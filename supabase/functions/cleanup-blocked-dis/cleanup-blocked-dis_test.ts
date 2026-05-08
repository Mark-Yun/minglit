import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";


const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "cleanup-blocked-dis",
};

function serviceRoleRequest() {
  return textRequest("http://localhost", "{}", {
    method: "POST",
    headers: { Authorization: "Bearer service-key" },
  });
}

Deno.test("unauthorized request returns 401", async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );

  await withEnv(ENV, async () => {
    const response = await handler(
      textRequest("http://localhost", "{}", { method: "POST" }),
    );
    const payload = await readJson(response);

    assertEquals(response.status, 401);
    assertEquals(payload.error, "Unauthorized");
  });
});

Deno.test("expired blocked_dis rows are deleted", async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );
  const { fetchMock, calls } = createFetchMock([{
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/blocked_dis") && req.method === "DELETE",
    handler: () =>
      jsonResponse([{ di_hash: "expired-1" }, { di_hash: "expired-2" }]),
  }]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const response = await handler(serviceRoleRequest());
      const payload = await readJson(response);

      assertEquals(response.status, 200);
      assertEquals(payload.success, true);
      assertEquals(payload.deleted_count, 2);
      assertEquals(
        calls.some((call) =>
          call.url.includes("/rest/v1/blocked_dis") &&
          call.method === "DELETE"
        ),
        true,
      );
    });
  });
});
