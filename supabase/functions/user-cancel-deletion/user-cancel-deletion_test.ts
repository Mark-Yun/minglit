import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  authenticatedJsonRequest,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";


const ENV = {
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "user-cancel-deletion",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

function profileRoute(deletedAt: string | null) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/user_profiles") && req.method === "GET",
    handler: () => jsonResponse({ deleted_at: deletedAt }),
  };
}

const restoreRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/user_profiles") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

Deno.test("인증 없는 요청 → 401", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const response = await handler(new Request("http://localhost", { method: "POST" }));
      const payload = await readJson(response);

      assertEquals(response.status, 401);
      assertEquals(payload.error, "Unauthorized");
    });
  });
});

Deno.test("유예 기간 중 취소 → deleted_at 복구", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const deletedAt = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString();

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    profileRoute(deletedAt),
    restoreRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const response = await handler(authenticatedJsonRequest("http://localhost", {}));
      const payload = await readJson(response);

      assertEquals(response.status, 200);
      assertEquals(payload.success, true);

      const restoreCall = calls.find(
        (call) => call.url.includes("/rest/v1/user_profiles") && call.method === "PATCH",
      );
      assertEquals(restoreCall !== undefined, true);
      assertEquals(JSON.parse(restoreCall!.body ?? "{}").deleted_at, null);
    });
  });
});

Deno.test("deleted_at 이 null인 유저 → 404", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    profileRoute(null),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const response = await handler(authenticatedJsonRequest("http://localhost", {}));
      const payload = await readJson(response);

      assertEquals(response.status, 404);
      assertEquals(payload.error, "탈퇴 진행 중인 계정이 아닙니다");
    });
  });
});

Deno.test("유예 기간 초과 → 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
  const deletedAt = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString();

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    profileRoute(deletedAt),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      const response = await handler(authenticatedJsonRequest("http://localhost", {}));
      const payload = await readJson(response);

      assertEquals(response.status, 400);
      assertEquals(payload.error, "탈퇴 유예 기간이 만료되었습니다");

      const restoreCall = calls.find(
        (call) => call.url.includes("/rest/v1/user_profiles") && call.method === "PATCH",
      );
      assertEquals(restoreCall, undefined);
    });
  });
});
