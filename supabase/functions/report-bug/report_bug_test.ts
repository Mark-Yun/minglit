import { assertEquals } from "@std/assert";
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

Deno.test("report-bug - happy path creates GitHub issue", async () => {
  // GITHUB_ACCESS_TOKEN is read at module load time, so we must set it
  // before captureServeHandler imports the module.
  await withEnv(
    { GITHUB_ACCESS_TOKEN: "test-token" },
    async () => {
      const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

      const { fetchMock } = createFetchMock([
        {
          matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
          handler: () => jsonResponse({ html_url: "https://github.com/Mark-Yun/minglit/issues/1" }),
        },
      ]);

      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", {
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
});

Deno.test("report-bug - missing title returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(
    { GITHUB_ACCESS_TOKEN: "test-token" },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", {
          description: "Bug without title",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required fields: title, description");
      });
    },
  );
});

Deno.test("report-bug - missing description returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(
    { GITHUB_ACCESS_TOKEN: "test-token" },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", {
          title: "Bug without description",
        });

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required fields: title, description");
      });
    },
  );
});

Deno.test("report-bug - malformed JSON returns 400", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(
    { GITHUB_ACCESS_TOKEN: "test-token" },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = textRequest("http://localhost", "{invalid-json");

        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    },
  );
});

Deno.test("report-bug - missing GITHUB_ACCESS_TOKEN returns 500", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([]);

  await withEnv(
    { GITHUB_ACCESS_TOKEN: undefined },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", {
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
});

Deno.test("report-bug - GitHub API failure returns 500", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: "https://api.github.com/repos/Mark-Yun/minglit/issues",
      handler: () => new Response("Unauthorized", { status: 401 }),
    },
  ]);

  await withEnv(
    { GITHUB_ACCESS_TOKEN: "bad-token" },
    async () => {
      await withMockedFetch(fetchMock, async () => {
        const request = jsonRequest("http://localhost", {
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
});
