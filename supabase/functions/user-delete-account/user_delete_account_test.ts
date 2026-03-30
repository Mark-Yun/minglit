import { assertEquals, assertExists } from "@std/assert";
import {
  authenticatedJsonRequest,
  captureServeHandler,
  createFetchMock,
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

function userProfileRoute(overrides?: { deleted_at?: string | null }) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/user_profiles") && req.method === "GET",
    handler: () =>
      jsonResponse([{
        deleted_at: overrides?.deleted_at ?? null,
      }]),
  };
}

function activeBookingsRoute(hasBooking = false) {
  return {
    matcher: (req: Request) =>
      decodeURIComponent(req.url).includes("/rest/v1/event_applications") &&
      req.method === "GET" &&
      decodeURIComponent(req.url).includes("events!inner"),
    handler: () =>
      jsonResponse(
        hasBooking
          ? [{
            id: "app-123",
            events: { start_time: "2099-01-01T00:00:00Z", status: "scheduled" },
          }]
          : [],
      ),
  };
}

function pendingRefundRoute(hasRefund = false) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/event_applications") &&
      req.method === "GET" &&
      req.url.includes("refund_status=eq.requested"),
    handler: () => jsonResponse(hasRefund ? [{ id: "app-456" }] : []),
  };
}

const updateUserProfileRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/user_profiles") && req.method === "PATCH",
  handler: () => jsonResponse({}),
};

const insertWithdrawalReasonRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/withdrawal_reasons") && req.method === "POST",
  handler: () => jsonResponse({}),
};

const deleteFcmTokensRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/fcm_tokens") && req.method === "DELETE",
  handler: () => jsonResponse({}),
};

Deno.test("unauthorized request returns 401", TEST_OPTS, async () => {
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
      await withNoIntervals(async () => {
        const response = await handler(
          textRequest("http://localhost", "{}", { method: "POST" }),
        );
        assertEquals(response.status, 401);
      });
    });
  });
});

Deno.test(
  "successful deletion sets deleted_at, stores anonymous reason, and removes FCM tokens",
  TEST_OPTS,
  async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      authRoute,
      userProfileRoute(),
      activeBookingsRoute(false),
      pendingRefundRoute(false),
      updateUserProfileRoute,
      insertWithdrawalReasonRoute,
      deleteFcmTokensRoute,
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(
            authenticatedJsonRequest("http://localhost", {
              reason_code: "privacy",
              reason_text: "더 이상 사용하지 않아요",
            }),
          );
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertExists(payload.grace_period_ends);

          const patchCall = calls.find(
            (call) =>
              call.url.includes("/rest/v1/user_profiles") &&
              call.method === "PATCH",
          );
          assertExists(patchCall);
          const patchBody = JSON.parse(patchCall.body!);
          assertEquals(typeof patchBody.deleted_at, "string");

          const reasonCall = calls.find(
            (call) =>
              call.url.includes("/rest/v1/withdrawal_reasons") &&
              call.method === "POST",
          );
          assertExists(reasonCall);
          const reasonBody = JSON.parse(reasonCall.body!);
          assertEquals(reasonBody.reason_code, "privacy");
          assertEquals(reasonBody.reason_text, "더 이상 사용하지 않아요");
          assertEquals("user_id" in reasonBody, false);

          const deleteCall = calls.find(
            (call) =>
              call.url.includes("/rest/v1/fcm_tokens") &&
              call.method === "DELETE",
          );
          assertExists(deleteCall);
        });
      });
    });
  },
);

Deno.test("active future booking blocks deletion", TEST_OPTS, async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );
  const { fetchMock, calls } = createFetchMock([
    authRoute,
    userProfileRoute(),
    activeBookingsRoute(true),
    pendingRefundRoute(false),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const response = await handler(
          authenticatedJsonRequest("http://localhost", {}),
        );
        const payload = await readJson(response);

        assertEquals(response.status, 400);
        assertEquals(
          payload.error,
          "Active bookings must be cancelled before deleting account",
        );
        assertEquals(
          calls.some((call) =>
            call.url.includes("/rest/v1/user_profiles") &&
            call.method === "PATCH"
          ),
          false,
        );
      });
    });
  });
});

Deno.test(
  "pending refund blocks deletion as unsettled balance",
  TEST_OPTS,
  async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      authRoute,
      userProfileRoute(),
      activeBookingsRoute(false),
      pendingRefundRoute(true),
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(
            authenticatedJsonRequest("http://localhost", {}),
          );
          const payload = await readJson(response);

          assertEquals(response.status, 400);
          assertEquals(
            payload.error,
            "Unsettled balance must be resolved before deleting account",
          );
          assertEquals(
            calls.some((call) =>
              call.url.includes("/rest/v1/user_profiles") &&
              call.method === "PATCH"
            ),
            false,
          );
        });
      });
    });
  },
);

Deno.test("already deleted user returns 409", TEST_OPTS, async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );
  const { fetchMock, calls } = createFetchMock([
    authRoute,
    userProfileRoute({ deleted_at: "2026-03-30T00:00:00Z" }),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const response = await handler(
          authenticatedJsonRequest("http://localhost", {}),
        );
        const payload = await readJson(response);

        assertEquals(response.status, 409);
        assertEquals(payload.error, "Account deletion already pending");
        assertEquals(calls.length, 2);
      });
    });
  });
});

Deno.test(
  "reason_text without reason_code falls back to other",
  TEST_OPTS,
  async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      authRoute,
      userProfileRoute(),
      activeBookingsRoute(false),
      pendingRefundRoute(false),
      updateUserProfileRoute,
      insertWithdrawalReasonRoute,
      deleteFcmTokensRoute,
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(
            authenticatedJsonRequest("http://localhost", {
              reason_text: "기타 사유",
            }),
          );

          assertEquals(response.status, 200);

          const reasonCall = calls.find(
            (call) =>
              call.url.includes("/rest/v1/withdrawal_reasons") &&
              call.method === "POST",
          );
          assertExists(reasonCall);
          const reasonBody = JSON.parse(reasonCall.body!);
          assertEquals(reasonBody.reason_code, "other");
          assertEquals(reasonBody.reason_text, "기타 사유");
        });
      });
    });
  },
);
