import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "valid-key",
};

Deno.test("github-stats-sync - unauthorized request returns 401", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const request = jsonRequest("http://localhost", {}, {
      headers: { Authorization: "Bearer wrong-key" },
    });
    const response = await handler(request);
    assertEquals(response.status, 401);
  });
});

Deno.test("github-stats-sync - authorized request is processed", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      {
        matcher: (req: Request) => req.url.includes("api.github.com"),
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req: Request) => req.url.includes("/rest/v1/rpc/upsert_github_daily_stat"),
        handler: () => jsonResponse(null),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      const request = jsonRequest("http://localhost", {}, {
        headers: { Authorization: "Bearer valid-key" },
      });
      const response = await handler(request);
      const payload = await readJson(response);

      assertEquals(response.status, 200);
      assertEquals(payload.success, true);
    });
  });
});
