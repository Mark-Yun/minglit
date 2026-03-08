import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

// ---------------------------------------------------------------------------
// Auth helpers — requireAuth calls Supabase /auth/v1/user, so we need to mock
// the endpoint and provide a Bearer token on every request.
// ---------------------------------------------------------------------------

const BASE_ENV = {
  GITHUB_ACCESS_TOKEN: "test-token",
  SUPABASE_URL: "https://test.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const SUPABASE_AUTH_ROUTE = {
  matcher: /auth\/v1\/user/,
  handler: () =>
    jsonResponse({ id: "test-user-id", email: "test@example.com" }),
};

/** Creates a POST request with Content-Type: application/json and a valid Bearer token. */
function authedJsonRequest(url: string, body: unknown): Request {
  return jsonRequest(url, body, {
    headers: { Authorization: "Bearer test-jwt" },
  });
}

/** Creates a plain-text POST request with a valid Bearer token. */
function authedTextRequest(url: string, body: string): Request {
  return textRequest(url, body, {
    headers: { Authorization: "Bearer test-jwt" },
  });
}

// ---------------------------------------------------------------------------
// Tests
// sanitizeResources/sanitizeOps disabled because supabase-js creates background
// intervals for auth token management when createClient() is called.
// ---------------------------------------------------------------------------

Deno.test({
  name: "report-bug - happy path creates GitHub issue",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    // GITHUB_ACCESS_TOKEN is read at module load time, so we must set it
    // before captureServeHandler imports the module.
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock } = createFetchMock([
          SUPABASE_AUTH_ROUTE,
          {
            matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
            handler: () => jsonResponse({ html_url: "https://github.com/Mark-Yun/minglit/issues/1" }),
          },
        ]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Test Bug",
            description: "Something went wrong",
            logs: "error at line 42",
            timestamp: "2026-01-01T00:00:00Z",
            platform: "android",
          });

          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.url, "https://github.com/Mark-Yun/minglit/issues/1");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - missing title returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock } = createFetchMock([SUPABASE_AUTH_ROUTE]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            description: "Bug without title",
          });

          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Missing required fields: title, description");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - missing description returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock } = createFetchMock([SUPABASE_AUTH_ROUTE]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Bug without description",
          });

          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Missing required fields: title, description");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - malformed JSON returns 400",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock } = createFetchMock([SUPABASE_AUTH_ROUTE]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedTextRequest("http://localhost", "{invalid-json");

          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(payload.error, "Invalid JSON body");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - missing GITHUB_ACCESS_TOKEN returns 500",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      { ...BASE_ENV, GITHUB_ACCESS_TOKEN: undefined },
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock } = createFetchMock([SUPABASE_AUTH_ROUTE]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Bug",
            description: "Details",
          });

          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(payload.error, "GITHUB_ACCESS_TOKEN is not set");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - GitHub API failure returns 500",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock } = createFetchMock([
          SUPABASE_AUTH_ROUTE,
          {
            matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
            handler: () => new Response("Unauthorized", { status: 401 }),
          },
        ]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Bug",
            description: "Details",
          });

          const response = await handler(request);
          const payload = await readJson(response);

          assertEquals(response.status, 500);
          assertEquals(typeof payload.error, "string");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - backward compat: old payload has no undefined and no new sections",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock, calls } = createFetchMock([
          SUPABASE_AUTH_ROUTE,
          {
            matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
            handler: () => jsonResponse({ html_url: "https://github.com/Mark-Yun/minglit/issues/10" }),
          },
        ]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Legacy Bug",
            description: "Old format report",
            logs: "some logs",
            timestamp: "2026-01-01T00:00:00Z",
          });

          const response = await handler(request);
          assertEquals(response.status, 200);

          const githubCall = calls.find((c) => c.url.includes("api.github.com"));
          const sentBody = JSON.parse(githubCall!.body!);
          assertEquals(sentBody.body.includes("undefined"), false);
          assertEquals(sentBody.body.includes("## Screenshot"), false);
          assertEquals(sentBody.body.includes("## Environment"), false);
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - screenshot and environment sections are included when provided",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock, calls } = createFetchMock([
          SUPABASE_AUTH_ROUTE,
          {
            matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
            handler: () => jsonResponse({ html_url: "https://github.com/Mark-Yun/minglit/issues/11" }),
          },
        ]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Visual Bug",
            description: "Screenshot attached",
            logs: "no errors",
            timestamp: "2026-01-02T00:00:00Z",
            screenshotUrl: "https://example.com/screenshot.png",
            environment: { appVersion: "1.0.0", osVersion: "14.0" },
          });

          const response = await handler(request);
          assertEquals(response.status, 200);

          const githubCall = calls.find((c) => c.url.includes("api.github.com"));
          const sentBody = JSON.parse(githubCall!.body!);
          assertStringIncludes(sentBody.body, "![Screenshot](https://example.com/screenshot.png)");
          assertStringIncludes(sentBody.body, "| appVersion | 1.0.0 |");
          assertStringIncludes(sentBody.body, "| osVersion | 14.0 |");
        });
      },
    );
  },
});

Deno.test({
  name: "report-bug - null screenshotUrl and environment produce no undefined in body",
  sanitizeResources: false,
  sanitizeOps: false,
  fn: async () => {
    await withEnv(
      BASE_ENV,
      async () => {
        const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

        const { fetchMock, calls } = createFetchMock([
          SUPABASE_AUTH_ROUTE,
          {
            matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
            handler: () => jsonResponse({ html_url: "https://github.com/Mark-Yun/minglit/issues/12" }),
          },
        ]);

        await withMockedFetch(fetchMock, async () => {
          const request = authedJsonRequest("http://localhost", {
            title: "Null Fields Bug",
            description: "Explicit nulls",
            logs: "fine",
            timestamp: "2026-01-03T00:00:00Z",
            screenshotUrl: null,
            environment: null,
          });

          const response = await handler(request);
          assertEquals(response.status, 200);

          const githubCall = calls.find((c) => c.url.includes("api.github.com"));
          const sentBody = JSON.parse(githubCall!.body!);
          assertEquals(sentBody.body.includes("undefined"), false);
          assertEquals(sentBody.body.includes("## Screenshot"), false);
          assertEquals(sentBody.body.includes("## Environment"), false);
        });
      },
    );
  },
});
