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

Deno.test("upsert_token — 정상 등록", async () => {
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

Deno.test("upsert_token — 같은 토큰 재등록 → last_updated_at 갱신", async () => {
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

Deno.test("upsert_token — token 누락 → 400", async () => {
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

Deno.test("upsert_token — 잘못된 device_type → 400", async () => {
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

Deno.test("delete_token — 정상 삭제", async () => {
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

Deno.test("delete_token — 존재하지 않는 토큰 → 에러 없이 성공", async () => {
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

Deno.test("delete_token — token 누락 → 400", async () => {
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

Deno.test("update_settings — marketing_consent 변경 → user_settings + user_consents 동시 반영", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    dbUpsertSettingsRoute({ marketing_consent: true }),
    {
      matcher: (req: Request) => req.url.includes("/rest/v1/user_consents") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
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

        const settingsCall = calls.find(
          (c) => c.url.includes("/rest/v1/user_settings") && c.method === "POST",
        );
        const settingsBody = JSON.parse(settingsCall!.body!);
        assertEquals(settingsBody.user_id, "user-123");
        assertEquals(settingsBody.marketing_consent, true);

        // Regression(#2040): marketing_consent 변경 시 user_consents도 sync되어야 함
        const consentCall = calls.find(
          (c) => c.url.includes("/rest/v1/user_consents") && c.method === "POST",
        );
        assertEquals(!!consentCall, true, "user_consents upsert must be called");
        const consentBody = JSON.parse(consentCall!.body!);
        assertEquals(consentBody.user_id, "user-123");
        assertEquals(consentBody.consent_key, "marketing_consent");
        assertEquals(consentBody.consented, true);
        assertEquals(consentBody.withdrawn_at, null);
      });
    });
  });
});

Deno.test("update_settings — marketing_consent false → user_consents withdrawn_at 설정 (Regression #2040)", async () => {
  const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

  const { fetchMock, calls } = createFetchMock([
    authRoute,
    dbUpsertSettingsRoute({ marketing_consent: false }),
    {
      matcher: (req: Request) => req.url.includes("/rest/v1/user_consents") && req.method === "POST",
      handler: () => jsonResponse({}),
    },
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = authenticatedJsonRequest("http://localhost", {
          action: "update_settings",
          settings: { marketing_consent: false },
        });
        const response = await handler(request);
        assertEquals(response.status, 200);

        // 설정 화면에서 수신거부 시 user_consents에 withdrawn_at이 설정되어야 함.
        // 이를 통해 notification-worker §50 가드가 해당 사용자에게 마케팅 알림을 차단한다.
        const consentCall = calls.find(
          (c) => c.url.includes("/rest/v1/user_consents") && c.method === "POST",
        );
        assertEquals(!!consentCall, true, "user_consents upsert must be called on opt-out");
        const consentBody = JSON.parse(consentCall!.body!);
        assertEquals(consentBody.consented, false);
        assertEquals(typeof consentBody.withdrawn_at, "string", "withdrawn_at must be set on opt-out");
      });
    });
  });
});

Deno.test("update_settings — service_notification 변경", async () => {
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

Deno.test("update_settings — 허용되지 않은 필드만 → 400", async () => {
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

Deno.test("update_settings — boolean이 아닌 값 → 400", async () => {
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

Deno.test("update_settings — settings 누락 → 400", async () => {
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

Deno.test("인증 없이 호출 → 401", async () => {
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

Deno.test("잘못된 action → 400", async () => {
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

Deno.test("action 누락 → 400", async () => {
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
        assertEquals(payload.error, "Missing or invalid \"action\" field");
      });
    });
  });
});

Deno.test("malformed JSON → 400", async () => {
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
