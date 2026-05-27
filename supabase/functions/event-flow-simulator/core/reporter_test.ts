import { assert, assertEquals } from "@std/assert";
import { reportFailure } from "./reporter.ts";
import type { Trace } from "./trace.ts";

const TARGET_SHA = "0123456789abcdef0123456789abcdef01234567";

function failedTrace(): Trace {
  return [{
    tick: 1,
    actorId: "user-1",
    action: {
      type: "user_apply",
      actorId: "user-1",
      payload: {},
      ef: "user-create-order",
    },
    status: 500,
    ok: false,
    error: "boom",
  }];
}

async function withMockedFetch(
  handler: (input: RequestInfo | URL, init?: RequestInit) => Response,
  fn: () => Promise<void>,
) {
  const originalFetch = globalThis.fetch;
  const originalToken = Deno.env.get("GITHUB_ACCESS_TOKEN");
  globalThis.fetch =
    ((input: RequestInfo | URL, init?: RequestInit) =>
      Promise.resolve(handler(input, init))) as typeof fetch;
  Deno.env.set("GITHUB_ACCESS_TOKEN", "test-token");
  try {
    await fn();
  } finally {
    globalThis.fetch = originalFetch;
    if (originalToken === undefined) {
      Deno.env.delete("GITHUB_ACCESS_TOKEN");
    } else {
      Deno.env.set("GITHUB_ACCESS_TOKEN", originalToken);
    }
  }
}

Deno.test("reportFailure writes failure status even when issue creation fails", async () => {
  const calls: Array<{ url: string; body: unknown }> = [];
  await withMockedFetch((input, init) => {
    const url = String(input);
    calls.push({
      url,
      body: init?.body ? JSON.parse(String(init.body)) : null,
    });
    if (url.endsWith("/issues")) {
      return new Response("issue api down", { status: 500 });
    }
    return new Response("{}", { status: 201 });
  }, async () => {
    const issueUrl = await reportFailure({
      runId: "run-1",
      trace: failedTrace(),
      violations: [],
      targetRef: "dev",
      targetSha: TARGET_SHA,
    });

    assertEquals(issueUrl, null);
    assertEquals(calls.length, 2);
    assert(calls[1].url.endsWith(`/statuses/${TARGET_SHA}`));
    assertEquals((calls[1].body as { state: string }).state, "failure");
    assertEquals(
      (calls[1].body as { context: string }).context,
      "dev-soak/backend-simulator",
    );
  });
});

Deno.test("reportFailure includes issue URL in failure status when issue creation succeeds", async () => {
  const calls: Array<{ url: string; body: unknown }> = [];
  const htmlUrl = "https://github.com/Mark-Yun/minglit/issues/9999";
  await withMockedFetch((input, init) => {
    const url = String(input);
    calls.push({
      url,
      body: init?.body ? JSON.parse(String(init.body)) : null,
    });
    if (url.endsWith("/issues")) {
      return Response.json({ html_url: htmlUrl }, { status: 201 });
    }
    return new Response("{}", { status: 201 });
  }, async () => {
    const issueUrl = await reportFailure({
      runId: "run-2",
      trace: failedTrace(),
      violations: [],
      targetRef: "dev",
      targetSha: TARGET_SHA,
    });

    assertEquals(issueUrl, htmlUrl);
    assertEquals(calls.length, 2);
    assertEquals((calls[1].body as { target_url: string }).target_url, htmlUrl);
  });
});
