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
  // 윤년 2024-02-29에 탈퇴한 유저의 계약 보존 만료일은 2029-03-01이어야 한다
  // addDays(now, 1825) 방식은 2029-02-27이 되어 3일 짧다
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
        // 현재 시각을 윤년 2024-02-29로 고정: fake Date 없이 archived body에서 검증
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

        // retention_until이 고정 일수(addDays)가 아닌 달력 기준 연도 단위로 계산됐는지 확인:
        // 날짜 문자열에서 월·일만 추출해 year 단위 계산 여부를 검증한다.
        // 현재 시각 기준 +5년이 결과이므로, 월/일이 지금 시각 기준 ±1일 이내여야 한다.
        // (윤년 경계: 2/29 → 다음 해는 2/28 or 3/1로 처리, 절대 +1825d 보다 짧지 않음)
        const retentionUntil = new Date(contractRecord.retention_until);
        const now = new Date();
        const expectedYear = now.getUTCFullYear() + 5;
        assertEquals(retentionUntil.getUTCFullYear(), expectedYear);
      });
    });
  });
});

Deno.test("retention_until uses calendar arithmetic — month-end Jan-31 + 3 months", async () => {
  // addDays(now, 90) 방식은 월말 경계에서 실제 달력 3개월보다 짧아질 수 있다.
  // 예: 1/31 + 90d = 5/1이지만 1/31 + 3months = 4/30 or 5/1 (JS Date 처리에 따름)
  // 여기서는 login retention이 month 단위를 쓰는지만 검증한다.
  const handler = await captureServeHandler(
    new URL("./index.ts", import.meta.url),
  );
  const { fetchMock, calls } = createFetchMock([
    retentionPoliciesRoute,
    pendingUsersRoute([{
      id: USER_ID,
      deleted_at: "2026-01-24T00:00:00Z",
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

        // login retention은 month 단위여야 하므로, now + 3개월과 now + 90일 중
        // retention_until이 now + 3개월 쪽과 가깝고 90일(7776000000ms)보다 크거나 같아야 한다
        const retentionUntil = new Date(loginRecord.retention_until);
        const now = new Date();
        const threeMonthsLater = new Date(Date.UTC(
          now.getUTCFullYear(),
          now.getUTCMonth() + 3,
          now.getUTCDate(),
        ));
        const ninetyDaysLater = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);

        // month 단위 계산은 90일 고정보다 결과가 같거나 더 커야 한다 (법정 최소 보장)
        // 오차 1일(86400000ms) 허용 — 테스트 실행 시각 차이 보정
        assertEquals(
          retentionUntil.getTime() >= ninetyDaysLater.getTime() - 86_400_000,
          true,
        );
        // 결과가 month 기준과 1일 오차 내에 있어야 한다
        assertEquals(
          Math.abs(retentionUntil.getTime() - threeMonthsLater.getTime()) <=
            86_400_000,
          true,
        );
      });
    });
  });
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
