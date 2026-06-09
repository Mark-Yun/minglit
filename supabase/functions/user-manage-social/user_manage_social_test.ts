import { assertEquals } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
} from "../_test_utils/mock_http.ts";

const TEST_USER_ID = "user-111";
const TEST_TARGET_ID = "partner-222";
const ENV = {
  ENVIRONMENT: "dev",
  MINGLIT_EF_TEST_FN_NAME: "user-manage-social",
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

// Helper: build auth mock route (always returns TEST_USER_ID)
function authRoute() {
  return {
    matcher: "/auth/v1/user",
    handler: () => jsonResponse({ id: TEST_USER_ID, email: "test@test.com" }),
  };
}

// ─────────────────────────────────────────
// set_interaction
// ─────────────────────────────────────────

Deno.test({
  name: "set_interaction - calls actor-aware RPC",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    let rpcBody: Record<string, unknown> | null = null;
    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: "/rest/v1/rpc/set_social_interaction_for_user",
        handler: async (req) => {
          rpcBody = await req.json();
          return jsonResponse(null);
        },
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "set_interaction",
          target_id: TEST_TARGET_ID,
          target_type: "partner",
          interaction_type: "bookmark",
          active: true,
        }));
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
        assertEquals(rpcBody?.p_user_id, TEST_USER_ID);
        assertEquals(rpcBody?.p_target_id, TEST_TARGET_ID);
        assertEquals(rpcBody?.p_target_type, "partner");
        assertEquals(rpcBody?.p_interaction_type, "bookmark");
        assertEquals(rpcBody?.p_active, true);
      });
    });
  },
});

Deno.test({
  name: "set_interaction - returns 400 when active is not boolean",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "set_interaction",
          target_id: TEST_TARGET_ID,
          target_type: "partner",
          interaction_type: "bookmark",
          active: "true",
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

// ─────────────────────────────────────────
// toggle
// ─────────────────────────────────────────

Deno.test({
  name: "toggle like - adds interaction when not exists",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );

    const { fetchMock, calls } = createFetchMock([
      authRoute(),
      // delete opposite (dislike)
      { matcher: "social_interactions?", handler: () => jsonResponse([]) },
      // select existing → null
      { matcher: "social_interactions?", handler: () => jsonResponse(null) },
      // insert
      {
        matcher: "social_interactions",
        handler: () => jsonResponse({}, { status: 201 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "toggle",
          target_id: TEST_TARGET_ID,
          target_type: "party",
          interaction_type: "like",
        }));
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

Deno.test({
  name: "toggle - returns 400 for invalid interaction_type",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "toggle",
          target_id: TEST_TARGET_ID,
          target_type: "party",
          interaction_type: "invalid_type",
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "toggle - returns 400 for invalid target_type",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "toggle",
          target_id: TEST_TARGET_ID,
          target_type: "invalid",
          interaction_type: "like",
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "toggle - returns 400 for missing fields",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "toggle",
          target_id: TEST_TARGET_ID,
          // missing target_type and interaction_type
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

// ─────────────────────────────────────────
// block / unblock
// ─────────────────────────────────────────

Deno.test({
  name: "block - succeeds",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      {
        matcher: "social_interactions",
        handler: () => jsonResponse({}, { status: 201 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "block",
          target_id: TEST_TARGET_ID,
        }));
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

Deno.test({
  name: "block - returns 400 when blocking self",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "block",
          target_id: TEST_USER_ID, // self
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "unblock - succeeds",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      { matcher: "social_interactions?", handler: () => jsonResponse([]) },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "unblock",
          target_id: TEST_TARGET_ID,
        }));
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

// ─────────────────────────────────────────
// report
// ─────────────────────────────────────────

Deno.test({
  name: "report - succeeds with block + report + details",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      authRoute(),
      // block upsert
      {
        matcher: "social_interactions",
        handler: () => jsonResponse({}, { status: 201 }),
      },
      // report upsert
      {
        matcher: "social_interactions",
        handler: () => jsonResponse({}, { status: 201 }),
      },
      // report_details insert
      {
        matcher: "report_details",
        handler: () => jsonResponse({}, { status: 201 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "report",
          target_id: TEST_TARGET_ID,
          reason: "spam",
          description: "Sending spam messages",
        }));
        assertEquals(res.status, 200);
        const body = await readJson(res);
        assertEquals(body.success, true);
      });
    });
  },
});

Deno.test({
  name: "report - returns 400 for invalid reason",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "report",
          target_id: TEST_TARGET_ID,
          reason: "invalid_reason",
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

Deno.test({
  name: "report - returns 400 when reporting self",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "report",
          target_id: TEST_USER_ID,
          reason: "spam",
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});

// ─────────────────────────────────────────
// common
// ─────────────────────────────────────────

Deno.test({
  name: "returns 401 without auth",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([
      {
        matcher: "/auth/v1/user",
        handler: () => jsonResponse({ error: "invalid" }, { status: 401 }),
      },
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(
          new Request("http://localhost", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ action: "block", target_id: "x" }),
          }),
        );
        assertEquals(res.status, 401);
      });
    });
  },
});

Deno.test({
  name: "returns 400 for unknown action",
  fn: async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock } = createFetchMock([authRoute()]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        const res = await handler(authenticatedJsonRequest("http://localhost", {
          action: "unknown_action",
        }));
        assertEquals(res.status, 400);
      });
    });
  },
});
