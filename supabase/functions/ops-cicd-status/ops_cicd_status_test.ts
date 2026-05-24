import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const BASE_ENV = {
  GITHUB_ACCESS_TOKEN: "test-gh-token",
  GITHUB_REPOSITORY: "Mark-Yun/minglit",
  SUPABASE_URL: "https://test.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "ops-cicd-status",
};

const AUTH_ROUTE = {
  matcher: /auth\/v1\/user/,
  handler: () =>
    jsonResponse({ id: "admin-user-id", email: "admin@example.com" }),
};

const ADMIN_ROLE_ROUTE = {
  matcher: /rest\/v1\/app_roles/,
  handler: () => jsonResponse({ role: "super_admin" }),
};

const WORKFLOW_FILES = [
  "dev-staging-pr-gate.yml",
  "monitor-dev-staging-health.yml",
  "dev-staging-dev-cut-gate.yml",
  "dev-staging-dev-cut.yml",
  "dev-pr-gate.yml",
  "dev-deploy.yml",
  "dev-rc-cut-gate.yml",
  "dev-rc-cut.yml",
  "rc-pr-gate.yml",
  "rc-deploy.yml",
  "rc-main-cut-gate.yml",
  "rc-main-cut.yml",
  "main-pr-gate.yml",
  "main-deploy.yml",
];

function authedRequest(): Request {
  return new Request("http://localhost", {
    method: "GET",
    headers: { Authorization: "Bearer test-jwt" },
  });
}

Deno.test("ops-cicd-status - returns normalized branch and issue snapshot", async () => {
  await withEnv(BASE_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
      AUTH_ROUTE,
      ADMIN_ROLE_ROUTE,
      {
        matcher: /\/actions\/workflows(\?|$)/,
        handler: () =>
          jsonResponse({
            workflows: WORKFLOW_FILES.map((file, index) => ({
              id: index + 1,
              name: file.replace(".yml", ""),
              path: `.github/workflows/${file}`,
              state: "active",
            })),
          }),
      },
      {
        matcher: /\/branches\/dev-staging$/,
        handler: () =>
          jsonResponse({
            name: "dev-staging",
            commit: { sha: "sha-dev-staging", url: "" },
          }),
      },
      {
        matcher: /\/branches\/dev$/,
        handler: () =>
          jsonResponse({ name: "dev", commit: { sha: "sha-dev", url: "" } }),
      },
      {
        matcher: /\/branches\/main$/,
        handler: () =>
          jsonResponse({ name: "main", commit: { sha: "sha-main", url: "" } }),
      },
      {
        matcher: /\/branches\?per_page=100$/,
        handler: () =>
          jsonResponse([{
            name: "rc/26.05.1",
            commit: { sha: "sha-rc", url: "" },
          }]),
      },
      {
        matcher: /\/actions\/workflows\/\d+\/runs/,
        handler: (req) =>
          jsonResponse({
            workflow_runs: [{
              id: 99,
              name: "run",
              html_url: req.url.replace(
                "https://api.github.com/repos/Mark-Yun/minglit",
                "https://github.com/Mark-Yun/minglit",
              ),
              status: "completed",
              conclusion: "success",
              head_branch: new URL(req.url).searchParams.get("branch"),
              head_sha: "sha",
              event: "workflow_dispatch",
              created_at: "2026-05-24T00:00:00Z",
              updated_at: "2026-05-24T00:10:00Z",
            }],
          }),
      },
      {
        matcher: /\/commits\/[^/]+\/status$/,
        handler: () => jsonResponse({ state: "success", statuses: [] }),
      },
      {
        matcher: /\/issues\?state=open&labels=ci-failure&per_page=25$/,
        handler: () =>
          jsonResponse([{
            number: 42,
            title: "[P1-high] dev-deploy failed",
            state: "open",
            html_url: "https://github.com/Mark-Yun/minglit/issues/42",
            labels: [{ name: "ci-failure" }, { name: "P1-high" }],
            updated_at: "2026-05-24T01:00:00Z",
          }]),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      const response = await handler(authedRequest());
      const body = await readJson(response);

      assertEquals(response.status, 200);
      assertEquals(body.success, true);
      assertEquals(body.branches.length, 4);
      assertEquals(body.branches[0].key, "dev-staging");
      assertEquals(body.branches[0].workflows.length, 4);
      assertEquals(body.issues[0].number, 42);
    });
  });
});

Deno.test("ops-cicd-status - rejects non super_admin user", async () => {
  await withEnv(BASE_ENV, async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock } = createFetchMock([
      AUTH_ROUTE,
      {
        matcher: /rest\/v1\/app_roles/,
        handler: () => jsonResponse(null),
      },
    ]);

    await withMockedFetch(fetchMock, async () => {
      const response = await handler(authedRequest());
      const body = await readJson(response);

      assertEquals(response.status, 403);
      assertEquals(body.error, "Forbidden");
    });
  });
});
