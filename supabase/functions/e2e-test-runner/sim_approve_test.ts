import { assertEquals } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simApproveVerifications } from "./sim_approve.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};

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

Deno.test("simApproveVerifications - 5 apps with approveRate=0.8 → 4 approved, 1 rejected", async () => {
  const appIds = ["app-1", "app-2", "app-3", "app-4", "app-5"];
  const submissionStatuses: Record<string, string> = {};

  const insertedSubmissions: Array<{ id: string; appId: string; status: string }> = [];

  const trackingMock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
          const appId = filters["id"] as string;
          const status = submissionStatuses[`app_${appId}`] ?? "pending_review";
          return {
            data: {
              id: appId,
              event_id: "event-1",
              ticket_id: "ticket-1",
              user_id: "user-1",
              status,
            },
            error: null,
          };
        },
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string };
          submissionStatuses[`app_${appId}`] = v.status;
          return { data: null, error: null };
        },
      },
      events: {
        select: makeEventSelectHandler(),
      },
      verifications: {
        select: makeVerificationSelectHandler("verif-1"),
      },
      verification_submissions: {
        insert: ({ values }) => {
          const v = values as { id: string; application_id: string; status: string };
          submissionStatuses[`sub_${v.id}`] = v.status;
          submissionStatuses[`sub_${v.id}_appId`] = v.application_id;
          insertedSubmissions.push({ id: v.id, appId: v.application_id, status: v.status });
          return { data: null, error: null };
        },
        update: ({ values, filters }) => {
          const subId = filters["id"] as string;
          const v = values as { status: string };
          submissionStatuses[`sub_${subId}`] = v.status;
          const appId = submissionStatuses[`sub_${subId}_appId`];
          if (appId) {
            submissionStatuses[`app_${appId}`] = v.status === "approved" ? "approved" : "rejected";
          }
          return { data: null, error: null };
        },
        select: ({ filters }) => {
          const subId = filters["id"] as string;
          const status = submissionStatuses[`sub_${subId}`] ?? "pending";
          return {
            data: {
              id: subId,
              status,
              partner_id: "partner-1",
              user_id: "user-1",
              verification_id: "verif-1",
            },
            error: null,
          };
        },
      },
      partner_verified_users: {
        select: () => ({ data: { id: "pvu-1" }, error: null }),
      },
    },
  });

  const result = await simApproveVerifications(
    trackingMock as unknown as SupabaseClient,
    appIds,
    noop,
    0.8,
  );

  assertEquals(result.approvedApplicationIds.length, 4);
  assertEquals(result.rejectedApplicationIds.length, 1);
});

Deno.test("simApproveVerifications - all approve when approveRate=1.0", async () => {
  const appIds = ["app-a", "app-b", "app-c"];
  const appStatuses: Record<string, string> = {};
  const subStatuses: Record<string, string> = {};
  const subAppMap: Record<string, string> = {};

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
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
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string };
          appStatuses[appId] = v.status;
          return { data: null, error: null };
        },
      },
      events: { select: makeEventSelectHandler() },
      verifications: { select: makeVerificationSelectHandler("verif-1") },
      verification_submissions: {
        insert: ({ values }) => {
          const v = values as { id: string; application_id: string };
          subStatuses[v.id] = "pending";
          subAppMap[v.id] = v.application_id;
          return { data: null, error: null };
        },
        update: ({ values, filters }) => {
          const subId = filters["id"] as string;
          const v = values as { status: string };
          subStatuses[subId] = v.status;
          const appId = subAppMap[subId];
          if (appId) appStatuses[appId] = v.status === "approved" ? "approved" : "rejected";
          return { data: null, error: null };
        },
        select: ({ filters }) => {
          const subId = filters["id"] as string;
          return {
            data: {
              id: subId,
              status: subStatuses[subId] ?? "pending",
              partner_id: "partner-1",
              user_id: "user-1",
              verification_id: "verif-1",
            },
            error: null,
          };
        },
      },
      partner_verified_users: {
        select: () => ({ data: { id: "pvu-1" }, error: null }),
      },
    },
  });

  const result = await simApproveVerifications(
    mock as unknown as SupabaseClient,
    appIds,
    noop,
    1.0,
  );

  assertEquals(result.approvedApplicationIds.length, 3);
  assertEquals(result.rejectedApplicationIds.length, 0);
});

Deno.test("simApproveVerifications - all reject when approveRate=0.0", async () => {
  const appIds = ["app-x", "app-y"];
  const appStatuses: Record<string, string> = {};
  const subStatuses: Record<string, string> = {};
  const subAppMap: Record<string, string> = {};

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
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
        update: ({ values, filters }) => {
          const appId = filters["id"] as string;
          const v = values as { status: string };
          appStatuses[appId] = v.status;
          return { data: null, error: null };
        },
      },
      events: { select: makeEventSelectHandler() },
      verifications: { select: makeVerificationSelectHandler("verif-1") },
      verification_submissions: {
        insert: ({ values }) => {
          const v = values as { id: string; application_id: string };
          subStatuses[v.id] = "pending";
          subAppMap[v.id] = v.application_id;
          return { data: null, error: null };
        },
        update: ({ values, filters }) => {
          const subId = filters["id"] as string;
          const v = values as { status: string };
          subStatuses[subId] = v.status;
          const appId = subAppMap[subId];
          if (appId) appStatuses[appId] = v.status === "approved" ? "approved" : "rejected";
          return { data: null, error: null };
        },
        select: ({ filters }) => {
          const subId = filters["id"] as string;
          return {
            data: {
              id: subId,
              status: subStatuses[subId] ?? "pending",
              partner_id: "partner-1",
              user_id: "user-1",
              verification_id: "verif-1",
            },
            error: null,
          };
        },
      },
      partner_verified_users: {
        select: () => ({ data: { id: "pvu-1" }, error: null }),
      },
    },
  });

  const result = await simApproveVerifications(
    mock as unknown as SupabaseClient,
    appIds,
    noop,
    0.0,
  );

  assertEquals(result.approvedApplicationIds.length, 0);
  assertEquals(result.rejectedApplicationIds.length, 2);
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

Deno.test("simApproveVerifications - no verification needed (direct status update)", async () => {
  const appIds = ["app-direct-1", "app-direct-2"];
  const appStatuses: Record<string, string> = {};

  const mock = createMockSupabaseClient({
    tables: {
      event_applications: {
        select: ({ filters }) => {
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
        update: ({ values, filters }) => {
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
    },
  });

  const result = await simApproveVerifications(
    mock as unknown as SupabaseClient,
    appIds,
    noop,
    1.0,
  );

  assertEquals(result.approvedApplicationIds.length, 2);
  assertEquals(result.rejectedApplicationIds.length, 0);
  assertEquals(appStatuses["app-direct-1"], "approved");
  assertEquals(appStatuses["app-direct-2"], "approved");
});
