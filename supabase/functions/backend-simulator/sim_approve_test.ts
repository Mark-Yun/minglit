import { assertEquals, assertRejects } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simApproveVerifications } from "./sim_approve.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};

// Intercept module-level EF calls via mock fetch. We replace globalThis.fetch
// for the duration of the test to simulate EF responses without a real server.
function withMockFetch<T>(
  handler: (url: string, init: RequestInit) => Response,
  fn: () => Promise<T>,
): Promise<T> {
  const original = globalThis.fetch;
  globalThis.fetch = (url: string | URL | Request, init?: RequestInit) =>
    Promise.resolve(handler(url.toString(), init ?? {}));
  return fn().finally(() => {
    globalThis.fetch = original;
  });
}

function makeEventSelectHandler() {
  return () => ({
    data: {
      id: "event-1",
      parties: {
        partner_id: "partner-1",
        required_verification_ids: [],
      },
    },
    error: null,
  });
}

function makeVerificationSelectHandler(verifId: string | null) {
  return () => ({
    data: verifId ? { id: verifId } : null,
    error: null,
  });
}

// Build a standard mock that handles partner_members + authAdminGetUserById
// so getPartnerEmail() resolves to "partner@test.com".
function makePartnerEmailMockOptions(extraTables: Record<string, unknown> = {}) {
  return {
    tables: {
      partner_members: {
        select: () => ({ data: [{ user_id: "partner-user-1" }], error: null }),
      },
      ...extraTables,
    },
    authAdminGetUserById: (_userId: string) => ({
      data: { user: { email: "partner@test.com" } },
      error: null,
    }),
  };
}

Deno.test("simApproveVerifications - empty list returns empty result", async () => {
  const mock = createMockSupabaseClient({});
  const result = await simApproveVerifications(
    mock as unknown as SupabaseClient,
    [],
    noop,
  );

  assertEquals(result.approvedApplicationIds, []);
  assertEquals(result.rejectedApplicationIds, []);
  assertEquals(result.assertions, []);
});

// Fix #1292: sanitizer 복원 — autoRefreshToken: false로 supabase-js interval 누수 해결
Deno.test({
  name: "simApproveVerifications - 5 apps with approveRate=0.8 → 4 approved, 1 rejected",
  fn: async () => {
    const appIds = ["app-1", "app-2", "app-3", "app-4", "app-5"];
    const appStatuses: Record<string, string> = {};
    const subAppMap: Record<string, string> = {};

    const mock = createMockSupabaseClient({
      ...makePartnerEmailMockOptions({
        event_applications: {
          select: ({ filters }: { filters: Record<string, unknown> }) => {
            const appId = filters["id"] as string;
            return {
              data: {
                id: appId,
                event_id: "event-1",
                ticket_id: "ticket-1",
                user_id: "user-1",
                status: appStatuses[appId] ?? "pending_review",
              },
              error: null,
            };
          },
        },
        events: { select: makeEventSelectHandler() },
        verifications: { select: makeVerificationSelectHandler("verif-1") },
        // Fix #1326: user-submit-verification EF로 전환 — verification_submissions 직접 insert 제거
        user_profiles: {
          select: () => ({ data: { username: "user_001" }, error: null }),
        },
        partner_verified_users: {
          select: () => ({ data: { id: "pvu-1" }, error: null }),
        },
      }),
    });

    Deno.env.set("SIM_USER_PASSWORD", "test-password");
    try {
      await withMockFetch((url, init) => {
        if (url.includes("auth/v1/token")) {
          return new Response(
            JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
            { status: 200 },
          );
        }
        // Fix #1326: user-submit-verification EF mock — returns submission_id
        if (url.includes("user-submit-verification")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const subId = `sub-${body.application_id as string}`;
          subAppMap[subId] = body.application_id as string;
          return new Response(JSON.stringify({ submission_id: subId }), { status: 200 });
        }
        if (url.includes("partner-review-submission")) {
          // Simulate EF approving/rejecting — update app status via side effect
          const body = JSON.parse((init.body as string) ?? "{}");
          const subId = body.submission_id as string;
          const appId = subAppMap[subId];
          if (appId) {
            appStatuses[appId] = body.result === "approved" ? "approved" : "rejected";
          }
          return new Response(JSON.stringify({ success: true }), { status: 200 });
        }
        return new Response(JSON.stringify({}), { status: 404 });
      }, async () => {
        const result = await simApproveVerifications(
          mock as unknown as SupabaseClient,
          appIds,
          noop,
          0.8,
          "https://mock.supabase.co",
          "anon-key",
        );

        assertEquals(result.approvedApplicationIds.length, 4);
        assertEquals(result.rejectedApplicationIds.length, 1);
      });
    } finally {
      Deno.env.delete("SIM_USER_PASSWORD");
    }
  },
});

Deno.test({
  name: "simApproveVerifications - all approve when approveRate=1.0",
  fn: async () => {
    const appIds = ["app-a", "app-b", "app-c"];
    const appStatuses: Record<string, string> = {};
    const subAppMap: Record<string, string> = {};

    const mock = createMockSupabaseClient({
      ...makePartnerEmailMockOptions({
        event_applications: {
          select: ({ filters }: { filters: Record<string, unknown> }) => {
            const appId = filters["id"] as string;
            return {
              data: {
                id: appId,
                event_id: "event-1",
                ticket_id: "ticket-1",
                user_id: "user-1",
                status: appStatuses[appId] ?? "pending_review",
              },
              error: null,
            };
          },
        },
        events: { select: makeEventSelectHandler() },
        verifications: { select: makeVerificationSelectHandler("verif-1") },
        // Fix #1326: user-submit-verification EF로 전환 — verification_submissions 직접 insert 제거
        user_profiles: {
          select: () => ({ data: { username: "user_001" }, error: null }),
        },
        partner_verified_users: {
          select: () => ({ data: { id: "pvu-1" }, error: null }),
        },
      }),
    });

    Deno.env.set("SIM_USER_PASSWORD", "test-password");
    try {
      await withMockFetch((url, init) => {
        if (url.includes("auth/v1/token")) {
          return new Response(
            JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
            { status: 200 },
          );
        }
        // Fix #1326: user-submit-verification EF mock — returns submission_id
        if (url.includes("user-submit-verification")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const subId = `sub-${body.application_id as string}`;
          subAppMap[subId] = body.application_id as string;
          return new Response(JSON.stringify({ submission_id: subId }), { status: 200 });
        }
        if (url.includes("partner-review-submission")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const subId = body.submission_id as string;
          const appId = subAppMap[subId];
          if (appId) appStatuses[appId] = "approved";
          return new Response(JSON.stringify({ success: true }), { status: 200 });
        }
        return new Response(JSON.stringify({}), { status: 404 });
      }, async () => {
        const result = await simApproveVerifications(
          mock as unknown as SupabaseClient,
          appIds,
          noop,
          1.0,
          "https://mock.supabase.co",
          "anon-key",
        );

        assertEquals(result.approvedApplicationIds.length, 3);
        assertEquals(result.rejectedApplicationIds.length, 0);
      });
    } finally {
      Deno.env.delete("SIM_USER_PASSWORD");
    }
  },
});

Deno.test({
  name: "simApproveVerifications - all reject when approveRate=0.0",
  fn: async () => {
    const appIds = ["app-x", "app-y"];
    const appStatuses: Record<string, string> = {};
    const subAppMap: Record<string, string> = {};

    const mock = createMockSupabaseClient({
      ...makePartnerEmailMockOptions({
        event_applications: {
          select: ({ filters }: { filters: Record<string, unknown> }) => {
            const appId = filters["id"] as string;
            return {
              data: {
                id: appId,
                event_id: "event-1",
                ticket_id: "ticket-1",
                user_id: "user-1",
                status: appStatuses[appId] ?? "pending_review",
              },
              error: null,
            };
          },
        },
        events: { select: makeEventSelectHandler() },
        verifications: { select: makeVerificationSelectHandler("verif-1") },
        // Fix #1326: user-submit-verification EF로 전환 — verification_submissions 직접 insert 제거
        user_profiles: {
          select: () => ({ data: { username: "user_001" }, error: null }),
        },
        partner_verified_users: {
          select: () => ({ data: { id: "pvu-1" }, error: null }),
        },
      }),
    });

    Deno.env.set("SIM_USER_PASSWORD", "test-password");
    try {
      await withMockFetch((url, init) => {
        if (url.includes("auth/v1/token")) {
          return new Response(
            JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
            { status: 200 },
          );
        }
        // Fix #1326: user-submit-verification EF mock — returns submission_id
        if (url.includes("user-submit-verification")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const subId = `sub-${body.application_id as string}`;
          subAppMap[subId] = body.application_id as string;
          return new Response(JSON.stringify({ submission_id: subId }), { status: 200 });
        }
        if (url.includes("partner-review-submission")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const subId = body.submission_id as string;
          const appId = subAppMap[subId];
          if (appId) appStatuses[appId] = "rejected";
          return new Response(JSON.stringify({ success: true }), { status: 200 });
        }
        return new Response(JSON.stringify({}), { status: 404 });
      }, async () => {
        const result = await simApproveVerifications(
          mock as unknown as SupabaseClient,
          appIds,
          noop,
          0.0,
          "https://mock.supabase.co",
          "anon-key",
        );

        assertEquals(result.approvedApplicationIds.length, 0);
        assertEquals(result.rejectedApplicationIds.length, 2);
      });
    } finally {
      Deno.env.delete("SIM_USER_PASSWORD");
    }
  },
});

Deno.test("simApproveVerifications - handles DB error gracefully (no throw)", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: () => ({ data: null, error: { message: "DB connection failed" } }),
      },
    },
  });

  const result = await simApproveVerifications(
    mock as unknown as SupabaseClient,
    ["app-err-1", "app-err-2"],
    noop,
    0.8,
  );

  assertEquals(result.approvedApplicationIds.length, 0);
  assertEquals(result.rejectedApplicationIds.length, 0);
});

// Fix #1283: EF failure always throws (strict parameter removed).
Deno.test({
  name: "simApproveVerifications - EF failure on verification flow throws error",
  fn: async () => {
    const mock = createMockSupabaseClient({
      ...makePartnerEmailMockOptions({
        event_applications: {
          select: ({ filters }: { filters: Record<string, unknown> }) => ({
            data: {
              id: filters["id"] as string,
              event_id: "event-1",
              ticket_id: "ticket-1",
              user_id: "user-1",
              status: "pending_review",
            },
            error: null,
          }),
        },
        events: { select: makeEventSelectHandler() },
        verifications: { select: makeVerificationSelectHandler("verif-1") },
        // Fix #1326: user-submit-verification EF로 전환 — verification_submissions 직접 insert 제거
        user_profiles: {
          select: () => ({ data: { username: "user_001" }, error: null }),
        },
      }),
    });

    Deno.env.set("SIM_USER_PASSWORD", "test-password");
    try {
      await withMockFetch((url, init) => {
        if (url.includes("auth/v1/token")) {
          return new Response(
            JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
            { status: 200 },
          );
        }
        // Fix #1326: user-submit-verification EF mock — succeeds so partner-review-submission is reached
        if (url.includes("user-submit-verification")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          return new Response(JSON.stringify({ submission_id: `sub-${body.application_id as string}` }), { status: 200 });
        }
        // EF returns 500 — should not fall back, should throw
        if (url.includes("partner-review-submission")) {
          return new Response(JSON.stringify({ error: "internal" }), { status: 500 });
        }
        return new Response(JSON.stringify({}), { status: 404 });
      }, async () => {
        await assertRejects(
          () => simApproveVerifications(
            mock as unknown as SupabaseClient,
            ["app-ef-fail-1"],
            noop,
            1.0,
            "https://mock.supabase.co",
            "anon-key",
          ),
          Error,
          "partner-review-submission EF returned 500",
        );
      });
    } finally {
      Deno.env.delete("SIM_USER_PASSWORD");
    }
  },
});

// Fix #1280: no-verification approve path uses partner-approve-application EF.
Deno.test({
  name: "simApproveVerifications - no verification needed: approve uses EF, reject uses direct DB",
  fn: async () => {
    const appIds = ["app-direct-1", "app-direct-2"];
    const appStatuses: Record<string, string> = {};
    const efApproveIds: string[] = [];

    const mock = createMockSupabaseClient({
      ...makePartnerEmailMockOptions({
        event_applications: {
          select: ({ filters }: { filters: Record<string, unknown> }) => {
            const appId = filters["id"] as string;
            return {
              data: {
                id: appId,
                event_id: "event-1",
                ticket_id: "ticket-1",
                user_id: "user-1",
                status: appStatuses[appId] ?? "pending_review",
              },
              error: null,
            };
          },
          update: ({ values, filters }: { values: unknown; filters: Record<string, unknown> }) => {
            const appId = filters["id"] as string;
            const v = values as { status: string };
            appStatuses[appId] = v.status;
            return { data: null, error: null };
          },
        },
        events: {
          select: () => ({
            data: {
              id: "event-1",
              parties: {
                partner_id: "partner-1",
                required_verification_ids: [],
              },
            },
            error: null,
          }),
        },
        verifications: {
          select: makeVerificationSelectHandler(null),
        },
      }),
    });

    Deno.env.set("SIM_USER_PASSWORD", "test-password");
    try {
      await withMockFetch((url, init) => {
        if (url.includes("auth/v1/token")) {
          return new Response(
            JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
            { status: 200 },
          );
        }
        if (url.includes("partner-approve-application")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const appId = body.application_id as string;
          efApproveIds.push(appId);
          appStatuses[appId] = "approved";
          return new Response(JSON.stringify({ approved: 1, application_id: appId }), { status: 200 });
        }
        return new Response(JSON.stringify({}), { status: 404 });
      }, async () => {
        // approveRate=1.0 → both apps go to approve path (EF), 0 to reject
        const result = await simApproveVerifications(
          mock as unknown as SupabaseClient,
          appIds,
          noop,
          1.0,
          "https://mock.supabase.co",
          "anon-key",
        );

        assertEquals(result.approvedApplicationIds.length, 2);
        assertEquals(result.rejectedApplicationIds.length, 0);
        // EF was called for both apps
        assertEquals(efApproveIds.includes("app-direct-1"), true);
        assertEquals(efApproveIds.includes("app-direct-2"), true);
      });
    } finally {
      Deno.env.delete("SIM_USER_PASSWORD");
    }
  },
});

// Fix #1328: no-verification reject path now uses partner-reject-application EF.
Deno.test({
  name: "simApproveVerifications - no verification needed: reject uses partner-reject-application EF",
  fn: async () => {
    const appIds = ["app-rej-1", "app-rej-2"];
    const appStatuses: Record<string, string> = {};
    const efRejectIds: string[] = [];

    const mock = createMockSupabaseClient({
      ...makePartnerEmailMockOptions({
        event_applications: {
          select: ({ filters }: { filters: Record<string, unknown> }) => {
            const appId = filters["id"] as string;
            return {
              data: {
                id: appId,
                event_id: "event-1",
                ticket_id: "ticket-1",
                user_id: "user-1",
                status: appStatuses[appId] ?? "pending_review",
              },
              error: null,
            };
          },
        },
        events: {
          select: () => ({
            data: {
              id: "event-1",
              parties: {
                partner_id: "partner-1",
                required_verification_ids: [],
              },
            },
            error: null,
          }),
        },
        verifications: {
          select: makeVerificationSelectHandler(null),
        },
      }),
    });

    Deno.env.set("SIM_USER_PASSWORD", "test-password");
    try {
      await withMockFetch((url, init) => {
        if (url.includes("auth/v1/token")) {
          return new Response(
            JSON.stringify({ access_token: "mock-token", token_type: "bearer", expires_in: 3600, refresh_token: "r", user: {} }),
            { status: 200 },
          );
        }
        // Fix #1328: partner-reject-application EF mock
        if (url.includes("partner-reject-application")) {
          const body = JSON.parse((init.body as string) ?? "{}");
          const appId = body.application_id as string;
          efRejectIds.push(appId);
          appStatuses[appId] = "rejected";
          return new Response(JSON.stringify({ success: true }), { status: 200 });
        }
        return new Response(JSON.stringify({}), { status: 404 });
      }, async () => {
        // approveRate=0.0 → all apps go to reject path → partner-reject-application EF
        const result = await simApproveVerifications(
          mock as unknown as SupabaseClient,
          appIds,
          noop,
          0.0,
          "https://mock.supabase.co",
          "anon-key",
        );

        assertEquals(result.approvedApplicationIds.length, 0);
        assertEquals(result.rejectedApplicationIds.length, 2);
        // EF was called for both apps
        assertEquals(efRejectIds.includes("app-rej-1"), true);
        assertEquals(efRejectIds.includes("app-rej-2"), true);
      });
    } finally {
      Deno.env.delete("SIM_USER_PASSWORD");
    }
  },
});
