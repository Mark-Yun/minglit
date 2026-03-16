import { assertEquals } from "@std/assert";
import { createMockSupabaseClient } from "../_test_utils/mock_supabase_client.ts";
import { simVerifySettlement, simTransitionToReady } from "./sim_settle.ts";
import type { SupabaseClient } from "@supabase/supabase-js";

const noop = () => {};

const GROSS = 100000;
const PLATFORM_FEE = Math.floor(GROSS * 5 / 100); // 5000
const PG_FEE = Math.floor(GROSS * 35 / 1000); // 3500
const VAT = Math.floor((PLATFORM_FEE + PG_FEE) * 10 / 100); // 850
const NET = GROSS - PLATFORM_FEE - PG_FEE - VAT; // 90650
const VALID_CHECKSUM = "a".repeat(64);

// ─────────────────────────────────────────────────────────
// simVerifySettlement tests
// ─────────────────────────────────────────────────────────

Deno.test("simVerifySettlement - passes when settlement exists with PENDING status and correct amounts", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: ({ filters }) => {
          if (filters["source_id"] === "event-1") {
            return {
              data: {
                id: "si-1",
                status: "PENDING",
                gross_amount: GROSS,
              },
              error: null,
            };
          }
          if (filters["id"] === "si-1") {
            return {
              data: {
                id: "si-1",
                status: "PENDING",
                gross_amount: GROSS,
                platform_fee_amount: PLATFORM_FEE,
                pg_fee_amount: PG_FEE,
                vat_amount: VAT,
                net_amount: NET,
                calc_checksum: VALID_CHECKSUM,
              },
              error: null,
            };
          }
          return { data: null, error: null };
        },
      },
      event_applications: {
        select: () => ({
          data: Array.from({ length: 5 }, () => ({ payment_amount: GROSS / 5 })),
          error: null,
        }),
      },
    },
  });

  const result = await simVerifySettlement(
    mock as unknown as SupabaseClient,
    ["event-1"],
    noop,
  );

  assertEquals(result.settlementIds, ["si-1"]);
  assertEquals(result.assertions.length, 3);
  assertEquals(result.assertions[0].check_name, "settlement_created");
  assertEquals(result.assertions[0].passed, true);
  assertEquals(result.assertions[1].check_name, "settlement_amounts");
  assertEquals(result.assertions[1].passed, true);
  assertEquals(result.assertions[2].check_name, "settlement_checksum");
  assertEquals(result.assertions[2].passed, true);
});

Deno.test("simVerifySettlement - empty eventIds returns empty result", async () => {
  const mock = createMockSupabaseClient({});

  const result = await simVerifySettlement(
    mock as unknown as SupabaseClient,
    [],
    noop,
  );

  assertEquals(result.settlementIds, []);
  assertEquals(result.assertions, []);
});

Deno.test("simVerifySettlement - handles no settlement (assertion fails, still returns)", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        select: () => ({ data: null, error: null }),
      },
    },
  });

  const result = await simVerifySettlement(
    mock as unknown as SupabaseClient,
    ["event-missing"],
    noop,
  );

  assertEquals(result.settlementIds, []);
  assertEquals(result.assertions.length, 1);
  assertEquals(result.assertions[0].check_name, "settlement_created");
  assertEquals(result.assertions[0].passed, false);
});

// ─────────────────────────────────────────────────────────
// simTransitionToReady tests
// ─────────────────────────────────────────────────────────

Deno.test("simTransitionToReady - settlement updated to READY after event_completed_at set", async () => {
  let updatedCompletedAt: string | null = null;
  let rpcCalled = false;

  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        update: ({ values }) => {
          const v = values as { event_completed_at: string };
          updatedCompletedAt = v.event_completed_at;
          return { data: null, error: null };
        },
        select: () => {
          const status = rpcCalled ? "READY" : "PENDING";
          return { data: { status }, error: null };
        },
      },
    },
    rpcs: {
      update_single_settlement_ready_status: () => {
        rpcCalled = true;
        return { data: null, error: null };
      },
    },
  });

  const result = await simTransitionToReady(
    mock as unknown as SupabaseClient,
    ["si-1"],
    noop,
  );

  assertEquals(result.readyIds, ["si-1"]);
  assertEquals(result.assertions.length, 1);
  assertEquals(result.assertions[0].check_name, "settlement_ready");
  assertEquals(result.assertions[0].passed, true);
  assertEquals(rpcCalled, true);
  assertEquals(typeof updatedCompletedAt, "string");
});

Deno.test("simTransitionToReady - empty settlementIds returns empty result", async () => {
  const mock = createMockSupabaseClient({});

  const result = await simTransitionToReady(
    mock as unknown as SupabaseClient,
    [],
    noop,
  );

  assertEquals(result.readyIds, []);
  assertEquals(result.assertions, []);
});

Deno.test("simTransitionToReady - assertion fails if still PENDING (mock does not auto-transition)", async () => {
  const mock = createMockSupabaseClient({
    tables: {
      settlement_items: {
        update: () => ({ data: null, error: null }),
        select: () => ({ data: { status: "PENDING" }, error: null }),
      },
    },
    rpcs: {
      update_settlement_ready_status: () => ({ data: null, error: null }),
    },
  });

  const result = await simTransitionToReady(
    mock as unknown as SupabaseClient,
    ["si-pending"],
    noop,
  );

  assertEquals(result.readyIds, []);
  assertEquals(result.assertions.length, 1);
  assertEquals(result.assertions[0].check_name, "settlement_ready");
  assertEquals(result.assertions[0].passed, false);
  assertEquals(result.assertions[0].actual, "PENDING");
});
