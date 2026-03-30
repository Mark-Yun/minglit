import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  authenticatedJsonRequest,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";
import { authRoute } from "../_test_utils/fixtures.ts";

const TEST_OPTS = { sanitizeOps: false, sanitizeResources: false };

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

// --- Route helpers ---

const dbUpsertTokenRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/fcm_tokens") && req.method === "POST",
  handler: () => jsonResponse({}),
};

const dbDeleteTokenRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/fcm_tokens") && req.method === "DELETE",
  handler: () => jsonResponse({}),
};

function dbUpsertSettingsRoute(overrides?: Record<string, unknown>) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/user_settings") && req.method === "POST",
    handler: () =>
      jsonResponse({
        user_id: "user-123",
        marketing_consent: false,
        service_notification: true,
        updated_at: new Date().toISOString(),
        ...overrides,
      }),
  };
}

// ===== upsert_token tests =====

Deno.test("upsert_token — 정상 등록", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    dbUpsertTokenRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "upsert_token",
          token: "fcm_token_abc",
          device_type: "android",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const upsertCall = calls.find(
          (c) => c.url.includes("/rest/v1/fcm_tokens") && c.method === "POST",
        );
        assertEquals(!!upsertCall, true);
        const body = JSON.parse(upsertCall!.body!);
        assertEquals(body.user_id, "user-123");
        assertEquals(body.token, "fcm_token_abc");
        assertEquals(body.device_type, "android");
      });
    });
  });
});

Deno.test("upsert_token — 같은 토큰 재등록 → last_updated_at 갱신", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    dbUpsertTokenRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "upsert_token",
          token: "existing_token",
          device_type: "ios",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const upsertCall = calls.find(
          (c) => c.url.includes("/rest/v1/fcm_tokens") && c.method === "POST",
        );
        const body = JSON.parse(upsertCall!.body!);
        assertEquals(typeof body.last_updated_at, "string");
      });
    });
  });
});

Deno.test("upsert_token — token 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "upsert_token",
          device_type: "android",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: token");
      });
    });
  });
});

Deno.test("upsert_token — 잘못된 device_type → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "upsert_token",
          token: "fcm_token",
          device_type: "desktop",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(
          payload.error,
          "Invalid device_type. Must be one of: android, ios, web",
        );
      });
    });
  });
});

// ===== delete_token tests =====

Deno.test("delete_token — 정상 삭제", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    dbDeleteTokenRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "delete_token",
          token: "fcm_token_abc",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);

        const deleteCall = calls.find(
          (c) => c.url.includes("/rest/v1/fcm_tokens") && c.method === "DELETE",
        );
        assertEquals(!!deleteCall, true);
      });
    });
  });
});

Deno.test("delete_token — 존재하지 않는 토큰 → 에러 없이 성공", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    dbDeleteTokenRoute,
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "delete_token",
          token: "nonexistent_token",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
      });
    });
  });
});

Deno.test("delete_token — token 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "delete_token",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: token");
      });
    });
  });
});

// ===== update_settings tests =====

Deno.test("update_settings — marketing_consent 변경 → DB 반영", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    dbUpsertSettingsRoute({ marketing_consent: true }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "update_settings",
          settings: { marketing_consent: true },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.settings.marketing_consent, true);

        const dbCall = calls.find(
          (c) => c.url.includes("/rest/v1/user_settings") && c.method === "POST",
        );
        const body = JSON.parse(dbCall!.body!);
        assertEquals(body.user_id, "user-123");
        assertEquals(body.marketing_consent, true);
      });
    });
  });
});

Deno.test("update_settings — service_notification 변경", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    authRoute,
    dbUpsertSettingsRoute({ service_notification: false }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "update_settings",
          settings: { service_notification: false },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.success, true);
        assertEquals(payload.settings.service_notification, false);
      });
    });
  });
});

Deno.test("update_settings — 허용되지 않은 필드만 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "update_settings",
          settings: { theme: "dark", language: "ko" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(
          payload.error,
          "No valid settings fields. Allowed: marketing_consent, service_notification",
        );
      });
    });
  });
});

Deno.test("update_settings — boolean이 아닌 값 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "update_settings",
          settings: { marketing_consent: "yes" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Field 'marketing_consent' must be a boolean");
      });
    });
  });
});

Deno.test("update_settings — settings 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "update_settings",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: settings");
      });
    });
  });
});

// ===== Auth & Edge cases =====

Deno.test("인증 없이 호출 → 401", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([
    {
      matcher: (req: Request) => req.url.includes("/auth/v1/user"),
      handler: () => jsonResponse({ error: "invalid token" }, { status: 401 }),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "upsert_token",
          token: "test",
          device_type: "android",
        });
        const response = await handler(request);

        assertEquals(response.status, 401);
      });
    });
  });
});

Deno.test("잘못된 action → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "invalid_action",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Unknown action: invalid_action");
      });
    });
  });
});

Deno.test("action 누락 → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          token: "test",
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Missing required field: action");
      });
    });
  });
});

Deno.test("malformed JSON → 400", TEST_OPTS, async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock } = createFetchMock([authRoute]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = textRequest("http://localhost", "{invalid-json", {
          headers: { Authorization: "Bearer test-token" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(payload.error, "Invalid JSON body");
      });
    });
  });
});
