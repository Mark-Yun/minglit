import { assertEquals, assertExists, assertNotEquals } from "@std/assert";
import { FakeTime } from "@std/testing/time";
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

const retentionPoliciesRoute = {
  matcher: (req: Request) =>
    req.url.includes("/rest/v1/retention_policies") && req.method === "GET",
  handler: () =>
    jsonResponse([
      { id: "deletion_grace", retention_days: 7, retention_calendar_value: null, retention_calendar_unit: null },
      { id: "blocked_di_records", retention_days: 30, retention_calendar_value: null, retention_calendar_unit: null },
      { id: "contract_retention", retention_days: 1825, retention_calendar_value: 5, retention_calendar_unit: "year" },
      { id: "payment_retention", retention_days: 1825, retention_calendar_value: 5, retention_calendar_unit: "year" },
      { id: "dispute_retention", retention_days: 1095, retention_calendar_value: 3, retention_calendar_unit: "year" },
      { id: "login_history_retention", retention_days: 90, retention_calendar_value: 3, retention_calendar_unit: "month" },
      { id: "consent_retention", retention_days: 730, retention_calendar_value: 2, retention_calendar_unit: "year" },
    ]),
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

Deno.test("unauthorized request returns 401", async () => {
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
  async () => {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      retentionPoliciesRoute,
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

// 회귀 방지: addDays 평탄화 시 윤년·월말 경계에서 법정 보존기간이 짧아지는 버그 (fix #1789)
Deno.test("retention_until uses calendar arithmetic — leap year 2024-02-29 + 5 years", async () => {
  // now = 2024-02-29 고정: addYears(5) = Date.UTC(2029, 1, 29) → 2월 29일 없음 → 2029-03-01
  // addDays(1825) 방식은 2029-02-27 (윤년 2024, 2028 포함하면 1827일 필요) — 3일 짧다
  const fakeTime = new FakeTime("2024-02-29T00:00:00Z");
  try {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      retentionPoliciesRoute,
      pendingUsersRoute([{
        id: USER_ID,
        deleted_at: "2024-02-22T00:00:00Z",
        di_hash: "di-leap-hash",
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
          assertEquals(response.status, 200);

          const archiveCall = calls.find((c) =>
            c.url.includes("/rest/v1/archived_records") && c.method === "POST"
          );
          assertExists(archiveCall);
          const archivedBody = JSON.parse(archiveCall!.body ?? "[]");

          const contractRecord = archivedBody.find(
            (r: { record_type: string }) => r.record_type === "contract",
          );
          assertExists(contractRecord);

          // 정확한 기대값: addYears(2024-02-29, 5) → Date.UTC(2029,1,29) overflow → 2029-03-01
          assertEquals(contractRecord.retention_until, "2029-03-01T00:00:00.000Z");
          // addDays(1825) 회귀 방지: 1825일 고정이면 2029-02-27 (3일 짧음)
          assertNotEquals(contractRecord.retention_until, "2029-02-27T00:00:00.000Z");
        });
      });
    });
  } finally {
    fakeTime.restore();
  }
});

Deno.test("retention_until uses calendar arithmetic — month-end Nov-30 + 3 months", async () => {
  // now = 2026-11-30 고정: addMonths(3) = Date.UTC(2027,1,30) overflow → 2027-03-02
  // addDays(90) 방식은 2027-02-28 (Feb 28일까지만 있음) — 2일 짧다
  const fakeTime = new FakeTime("2026-11-30T00:00:00Z");
  try {
    const handler = await captureServeHandler(
      new URL("./index.ts", import.meta.url),
    );
    const { fetchMock, calls } = createFetchMock([
      retentionPoliciesRoute,
      pendingUsersRoute([{
        id: USER_ID,
        deleted_at: "2026-11-25T00:00:00Z",
        di_hash: "di-monthend-hash",
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
          assertEquals(response.status, 200);

          const archiveCall = calls.find((c) =>
            c.url.includes("/rest/v1/archived_records") && c.method === "POST"
          );
          assertExists(archiveCall);
          const archivedBody = JSON.parse(archiveCall!.body ?? "[]");

          const loginRecord = archivedBody.find(
            (r: { record_type: string }) => r.record_type === "login",
          );
          assertExists(loginRecord);

          // 정확한 기대값: addMonths(2026-11-30, 3) → Date.UTC(2027,1,30) overflow → 2027-03-02
          assertEquals(loginRecord.retention_until, "2027-03-02T00:00:00.000Z");
          // addDays(90) 회귀 방지: Nov 30 + 90d = 2027-02-28 (Feb 28까지만 있음)
          assertNotEquals(loginRecord.retention_until, "2027-02-28T00:00:00.000Z");
        });
      });
    });
  } finally {
    fakeTime.restore();
  }
});

Deno.test("no eligible users returns zero summary", async () => {
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );
  const { fetchMock, calls } = createFetchMock([
    retentionPoliciesRoute,
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
        assertEquals(calls.length, 2); // retention_policies + user_profiles
      });
    });
  });
});
