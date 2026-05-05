import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "user-mark-match-results-viewed",
};

const OWN_APP_ID = "11111111-1111-4111-8111-111111111111";
const OTHER_APP_ID = "22222222-2222-4222-8222-222222222222";

function applicationRoute(overrides?: {
  id?: string;
  user_id?: string;
  match_results_viewed_at?: string | null;
}) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/event_applications") && req.method === "GET",
    handler: () =>
      jsonResponse({
        id: overrides?.id ?? OWN_APP_ID,
        user_id: overrides?.user_id ?? "user-123",
        match_results_viewed_at: overrides?.match_results_viewed_at ?? null,
      }),
  };
}

const updateRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

Deno.test("authenticated user marks own application as viewed -> 200", async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    applicationRoute(),
    updateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          application_id: OWN_APP_ID,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.already_viewed, false);

        const patchCall = calls.find(
          (call) =>
            call.url.includes("/rest/v1/event_applications") &&
            call.method === "PATCH",
        );
        assertEquals(!!patchCall, true);
      });
    });
  });
});

Deno.test("authenticated user cannot mark another user's application -> error", async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    applicationRoute({ id: OTHER_APP_ID, user_id: "user-999" }),
    updateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          application_id: OTHER_APP_ID,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 403);
        assertEquals(payload.error, "Forbidden");

        const patchCall = calls.find(
          (call) =>
            call.url.includes("/rest/v1/event_applications") &&
            call.method === "PATCH",
        );
        assertEquals(patchCall, undefined);
      });
    });
  });
});

Deno.test("marking an already-viewed application is idempotent -> 200", async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    applicationRoute({
      match_results_viewed_at: "2026-05-05T00:00:00.000Z",
    }),
    updateRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          application_id: OWN_APP_ID,
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.already_viewed, true);

        const patchCall = calls.find(
          (call) =>
            call.url.includes("/rest/v1/event_applications") &&
            call.method === "PATCH",
        );
        assertEquals(patchCall, undefined);
      });
    });
  });
});
