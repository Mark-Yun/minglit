import assert from "node:assert/strict";
import test from "node:test";

import type { SupabaseClient, User } from "@supabase/supabase-js";

import {
  fetchCurrentPartner,
  resolvePartnerDashboardGate,
  resolvePartnerLoginGate,
  type ManagedPartner,
} from "./partner-dashboard";

const testUser = { id: "user-1", email: "owner@example.com" } as User;

test("dashboard guard redirects anonymous users to login with next dashboard", async () => {
  const gate = await resolvePartnerDashboardGate(createSupabase({ sessionUser: null }));

  assert.deepEqual(gate, {
    status: "anonymous",
    loginRedirect: "/login?next=%2Fdashboard",
  });
});

test("partner lookup returns null when no partner member permission exists", async () => {
  const partner = await fetchCurrentPartner(
    createSupabase({
      sessionUser: testUser,
      permissionRows: [],
    }),
    testUser,
  );

  assert.equal(partner, null);
});

test("dashboard guard shows no-access when the signed-in user has no partner permission", async () => {
  const gate = await resolvePartnerDashboardGate(
    createSupabase({
      sessionUser: testUser,
      permissionRows: [],
    }),
  );

  assert.deepEqual(gate, {
    status: "no-access",
    email: "owner@example.com",
  });
});

test("dashboard guard returns the managed partner for authorized users", async () => {
  const gate = await resolvePartnerDashboardGate(createAuthorizedSupabase());

  assert.equal(gate.status, "ready");
  assert.deepEqual(gate, {
    status: "ready",
    partner: expectedPartner,
    email: "owner@example.com",
  });
});

test("login guard redirects authorized users to the sanitized next path", async () => {
  const gate = await resolvePartnerLoginGate(createAuthorizedSupabase(), "/dashboard/events");

  assert.deepEqual(gate, {
    status: "ready",
    redirectTo: "/dashboard/events",
  });
});

const expectedPartner: ManagedPartner = {
  id: "partner-1",
  name: "Minglit Lounge",
  introduction: "Partner intro",
  contact_email: "partner@example.com",
  role: "owner",
  permissions: ["event.manage", "settlement.read"],
};

function createAuthorizedSupabase(): SupabaseClient {
  return createSupabase({
    sessionUser: testUser,
    permissionRows: [
      {
        partner_id: "partner-1",
        role: "owner",
        permissions: ["event.manage", "settlement.read"],
      },
    ],
    partnerRow: {
      id: "partner-1",
      name: "Minglit Lounge",
      introduction: "Partner intro",
      contact_email: "partner@example.com",
      is_active: true,
    },
  });
}

type PermissionRow = {
  partner_id: string;
  role: string;
  permissions: string[] | null;
};

type PartnerRow = {
  id: string;
  name: string;
  introduction: string | null;
  contact_email: string | null;
  is_active: boolean | null;
};

type FakeSupabaseOptions = {
  sessionUser: User | null;
  permissionRows?: PermissionRow[];
  partnerRow?: PartnerRow | null;
};

function createSupabase({
  sessionUser,
  permissionRows = [],
  partnerRow = null,
}: FakeSupabaseOptions): SupabaseClient {
  return {
    auth: {
      getSession: async () => ({
        data: { session: sessionUser ? { user: sessionUser } : null },
        error: null,
      }),
    },
    from(table: string) {
      if (table === "partner_member_permissions") {
        return permissionQuery(permissionRows);
      }

      if (table === "partners") {
        return partnerQuery(partnerRow);
      }

      throw new Error(`Unexpected table: ${table}`);
    },
  } as unknown as SupabaseClient;
}

function permissionQuery(rows: PermissionRow[]) {
  return {
    select() {
      return this;
    },
    eq() {
      return this;
    },
    limit() {
      return this;
    },
    returns: async () => ({ data: rows, error: null }),
  };
}

function partnerQuery(row: PartnerRow | null) {
  return {
    select() {
      return this;
    },
    eq() {
      return this;
    },
    single: async () => ({ data: row, error: null }),
  };
}
