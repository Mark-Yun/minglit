import { assertEquals, assertExists } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonResponse,
  readJson,
  textRequest,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";

const TEST_OPTS = { sanitizeOps: false, sanitizeResources: false };

const ENV = {
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "service-key",
};

const USER_ID = "11111111-1111-4111-8111-111111111111";

function serviceRoleRequest() {
  return textRequest("http://localhost", "{}", {
    method: "POST",
    headers: { Authorization: "Bearer service-key" },
  });
}

function pendingUsersRoute(users: Array<Record<string, unknown>>) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/user_profiles") && req.method === "GET",
    handler: () => jsonResponse(users),
  };
}

const eventApplicationsRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/event_applications") && req.method === "GET",
  handler: () =>
    jsonResponse([{
      id: "app-1",
      event_id: "event-1",
      ticket_id: "ticket-1",
      status: "paid",
      payment_id: "payment-1",
      payment_amount: 50000,
      refund_amount: 0,
      refund_status: "none",
      created_at: "2026-03-01T00:00:00Z",
      updated_at: "2026-03-02T00:00:00Z",
    }]),
};

const reportDetailsRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/report_details") && req.method === "GET",
  handler: () =>
    jsonResponse([{
      id: "report-1",
      target_id: "target-1",
      target_type: "partner",
      reason: "refund-delay",
      description: "환불이 지연되었어요",
      created_at: "2026-03-05T00:00:00Z",
    }]),
};

const authAdminGetUserRoute = {
  matcher: (req: Request) =>
    req.url.includes(`/auth/v1/admin/users/${USER_ID}`) && req.method === "GET",
  handler: () =>
    jsonResponse({
      user: {
        id: USER_ID,
        created_at: "2026-01-01T00:00:00Z",
        last_sign_in_at: "2026-03-20T12:00:00Z",
        app_metadata: {
          provider: "email",
          providers: ["email"],
        },
      },
    }),
};

const blockedDisCheckRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/blocked_dis") && req.method === "GET",
  handler: () => jsonResponse([]),
};

const archiveInsertRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/archived_records") && req.method === "POST",
  handler: () => jsonResponse({}),
};

const blockedDisUpsertRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/blocked_dis") && req.method === "POST",
  handler: () => jsonResponse({}),
};

const authDeleteRoute = {
  matcher: (req: Request) =>
    req.url.includes(`/auth/v1/admin/users/${USER_ID}`) &&
    req.method === "DELETE",
  handler: () => jsonResponse({ user: { id: USER_ID } }),
};

const userConsentsRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/user_consents") && req.method === "GET",
  handler: () =>
    jsonResponse([
      {
        id: "consent-1",
        consent_key: "terms_of_service",
        consented: true,
        policy_version: 1,
        consented_at: "2026-01-15T00:00:00Z",
        withdrawn_at: null,
        created_at: "2026-01-15T00:00:00Z",
      },
      {
        id: "consent-2",
        consent_key: "privacy_collection",
        consented: true,
        policy_version: 1,
        consented_at: "2026-01-15T00:00:00Z",
        withdrawn_at: null,
        created_at: "2026-01-15T00:00:00Z",
      },
      {
        id: "consent-3",
        consent_key: "marketing_consent",
        consented: false,
        policy_version: 1,
        consented_at: "2026-01-15T00:00:00Z",
        withdrawn_at: "2026-02-01T00:00:00Z",
        created_at: "2026-01-15T00:00:00Z",
      },
    ]),
};

Deno.test("unauthorized request returns 401", TEST_OPTS, async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );

  await withEnv(ENV, async () => {
    await withNoIntervals(async () => {
      const response = await handler(
        textRequest("http://localhost", "{}", { method: "POST" }),
      );
      const payload = await readJson(response);

      assertEquals(response.status, 401);
      assertEquals(payload.error, "Unauthorized");
    });
  });
});

Deno.test(
  "successful run archives records, blocks DI, and deletes auth user",
  TEST_OPTS,
  async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      pendingUsersRoute([{
        id: USER_ID,
        deleted_at: "2026-03-21T00:00:00Z",
        di_hash: "di-hash-1",
      }]),
      eventApplicationsRoute,
      reportDetailsRoute,
      userConsentsRoute,
      authAdminGetUserRoute,
      blockedDisCheckRoute,
      archiveInsertRoute,
      blockedDisUpsertRoute,
      authDeleteRoute,
    ]);

    await withEnv(ENV, async () => {
      await withMockedFetch(fetchMock, async () => {
        await withNoIntervals(async () => {
          const response = await handler(serviceRoleRequest());
          const payload = await readJson(response);

          assertEquals(response.status, 200);
          assertEquals(payload.success, true);
          assertEquals(payload.processed_count, 1);
          assertEquals(payload.deleted_count, 1);
          assertEquals(payload.blocked_count, 1);
          assertEquals(payload.failed_count, 0);
          assertEquals(payload.archived_record_count, 7);

          const archiveCall = calls.find((call) =>
            call.url.includes("/rest/v1/archived_records") &&
            call.method === "POST"
          );
          assertExists(archiveCall);
          const archivedBody = JSON.parse(archiveCall!.body ?? "[]");
          assertEquals(archivedBody.length, 7);
          assertEquals(
            archivedBody.some((row: { record_type: string }) =>
              row.record_type === "login"
            ),
            true,
          );
          assertEquals(
            archivedBody.some((row: { record_type: string }) =>
              row.record_type === "consent"
            ),
            true,
          );

          const consentRecords = archivedBody.filter(
            (row: { record_type: string }) => row.record_type === "consent",
          );
          assertEquals(consentRecords.length, 3);
          assertEquals(
            consentRecords.some((r: { record_data: { consent_key: string } }) =>
              r.record_data.consent_key === "terms_of_service"
            ),
            true,
          );

          const blockedCall = calls.find((call) =>
            call.url.includes("/rest/v1/blocked_dis") && call.method === "POST"
          );
          assertExists(blockedCall);
          const blockedBody = JSON.parse(blockedCall!.body ?? "{}");
          assertEquals(blockedBody.di_hash, "di-hash-1");

          assertEquals(
            calls.some((call) =>
              call.url.includes(`/auth/v1/admin/users/${USER_ID}`) &&
              call.method === "DELETE"
            ),
            true,
          );
        });
      });
    });
  },
);

Deno.test("no eligible users returns zero summary", TEST_OPTS, async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );
  const { fetchMock, calls } = createFetchMock([
    pendingUsersRoute([]),
  ]);

  await withEnv(ENV, async () => {
    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const response = await handler(serviceRoleRequest());
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.processed_count, 0);
        assertEquals(payload.deleted_count, 0);
        assertEquals(payload.failed_count, 0);
        assertEquals(calls.length, 1);
      });
    });
  });
});
