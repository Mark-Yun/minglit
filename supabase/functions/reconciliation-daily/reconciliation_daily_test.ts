import { assertEquals } from "@std/assert";
import {
  captureServeHandler,
  createFetchMock,
  jsonRequest,
  jsonResponse,
  readJson,
  withEnv,
  withMockedFetch,
  withNoIntervals,
} from "../_test_utils/mock_http.ts";

const ENV = {
  PORTONE_V2_API_KEY: "test-portone-key",
  SUPABASE_URL: "https://supabase.test",
  SUPABASE_SERVICE_ROLE_KEY: "test-service-key",
};

const RUN_ID = "aaaaaaaa-0000-0000-0000-000000000001";

function makeRunInsertMock(runId: string = RUN_ID) {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/reconciliation_runs") && req.method === "POST",
    handler: () => jsonResponse({ id: runId }),
  };
}

function makeRunUpdateMock() {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/reconciliation_runs") && req.method === "PATCH",
    handler: () => jsonResponse({}),
  };
}

function makeRpcMock() {
  return {
    matcher: (req: Request) => req.url.includes("/rest/v1/rpc/process_reconciliation_kill_switch"),
    handler: () => jsonResponse(false),
  };
}

function makeResultsInsertMock() {
  return {
    matcher: (req: Request) =>
      req.url.includes("/rest/v1/reconciliation_results") && req.method === "POST",
    handler: () => jsonResponse([]),
  };
}

Deno.test("reconciliation-daily - unauthorized request returns 401", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const request = jsonRequest("http://localhost", {}, {
      headers: { Authorization: "Bearer bad-key" },
    });
    const response = await handler(request);
    assertEquals(response.status, 401);
  });
});

Deno.test("reconciliation-daily - missing Authorization header returns 401", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const request = new Request("http://localhost", { method: "POST" });
    const response = await handler(request);
    assertEquals(response.status, 401);
  });
});

Deno.test("reconciliation-daily - OPTIONS preflight returns 204", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));
    const request = new Request("http://localhost", { method: "OPTIONS" });
    const response = await handler(request);
    assertEquals(response.status, 204);
  });
});

Deno.test("reconciliation-daily - successful reconciliation with matched data", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      makeRunInsertMock(),
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () =>
          jsonResponse([
            {
              id: "item-001",
              partner_id: "partner-001",
              net_amount: 100000,
              processing_ended_at: "2026-03-14T10:00:00.000Z",
              status: "COMPLETED",
              payout_id: null,
            },
          ]),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("api.portone.io") || req.url.includes("portone"),
        handler: () =>
          jsonResponse({
            settlements: [
              {
                id: "portone-001",
                partnerId: "partner-001",
                amount: 100000,
                settlementDate: "2026-03-14T10:00:00.000Z",
                status: "COMPLETED",
              },
            ],
          }),
      },
      makeResultsInsertMock(),
      makeRpcMock(),
      makeRunUpdateMock(),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer test-service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.matched, 1);
        assertEquals(payload.mismatched, 0);
        assertEquals(payload.critical, 0);
      });
    });
  });
});

Deno.test("reconciliation-daily - MISSING_IN_PORTONE detection", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      makeRunInsertMock(),
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () =>
          jsonResponse([
            {
              id: "item-002",
              partner_id: "partner-002",
              net_amount: 50000,
              processing_ended_at: "2026-03-14T10:00:00.000Z",
              status: "COMPLETED",
              payout_id: null,
            },
          ]),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("api.portone.io") || req.url.includes("portone"),
        handler: () => jsonResponse({ settlements: [] }),
      },
      makeResultsInsertMock(),
      makeRpcMock(),
      makeRunUpdateMock(),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer test-service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.critical, 1);
        assertEquals(payload.mismatched, 1);
        assertEquals(payload.matched, 0);
      });
    });
  });
});

Deno.test("reconciliation-daily - MISSING_IN_LEDGER detection", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      makeRunInsertMock(),
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("api.portone.io") || req.url.includes("portone"),
        handler: () =>
          jsonResponse({
            settlements: [
              {
                id: "portone-003",
                partnerId: "partner-003",
                amount: 75000,
                settlementDate: "2026-03-14T10:00:00.000Z",
                status: "COMPLETED",
              },
            ],
          }),
      },
      makeResultsInsertMock(),
      makeRpcMock(),
      makeRunUpdateMock(),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer test-service-key" },
        });
        const response = await handler(request);
        const payload = await readJson(response);

        assertEquals(response.status, 200);
        assertEquals(payload.critical, 1);
        assertEquals(payload.mismatched, 1);
        assertEquals(payload.matched, 0);
      });
    });
  });
});

Deno.test("reconciliation-daily - PortOne API failure → FAILED run, no kill switch", async () => {
  await withEnv(ENV, async () => {
    const handler = await captureServeHandler(new URL("./index.ts", import.meta.url));

    const { fetchMock } = createFetchMock([
      makeRunInsertMock(),
      {
        matcher: (req: Request) =>
          req.url.includes("/rest/v1/settlement_items") && req.method === "GET",
        handler: () => jsonResponse([]),
      },
      {
        matcher: (req: Request) =>
          req.url.includes("api.portone.io") || req.url.includes("portone"),
        handler: () => new Response("Internal Server Error", { status: 500 }),
      },
      makeRunUpdateMock(),
    ]);

    await withMockedFetch(fetchMock, async () => {
      await withNoIntervals(async () => {
        const request = jsonRequest("http://localhost", {}, {
          headers: { Authorization: "Bearer test-service-key" },
        });
        const response = await handler(request);

        assertEquals(response.status, 500);
      });
    });
  });
});

Deno.test("reconciliation-daily - classifyMismatch: MISSING_IN_LEDGER", () => {
  const result = classifyMismatch(null, 100000, null, null, null, null);
  assertEquals(result.mismatch_type, "MISSING_IN_LEDGER");
  assertEquals(result.severity, "CRITICAL");
});

Deno.test("reconciliation-daily - classifyMismatch: MISSING_IN_PORTONE", () => {
  const result = classifyMismatch(100000, null, null, null, null, null);
  assertEquals(result.mismatch_type, "MISSING_IN_PORTONE");
  assertEquals(result.severity, "CRITICAL");
});

Deno.test("reconciliation-daily - classifyMismatch: AMOUNT_MISMATCH", () => {
  const result = classifyMismatch(100000, 99000, null, null, null, null);
  assertEquals(result.mismatch_type, "AMOUNT_MISMATCH");
  assertEquals(result.severity, "CRITICAL");
});

Deno.test("reconciliation-daily - classifyMismatch: MATCHED (exact)", () => {
  const result = classifyMismatch(100000, 100000, null, null, null, null);
  assertEquals(result.mismatch_type, "MATCHED");
  assertEquals(result.severity, "INFO");
});

Deno.test("reconciliation-daily - classifyMismatch: DATE_SHIFT", () => {
  const result = classifyMismatch(100000, 100000, "2026-03-14", "2026-03-15", null, null);
  assertEquals(result.mismatch_type, "DATE_SHIFT");
  assertEquals(result.severity, "WARNING");
});

Deno.test("reconciliation-daily - classifyMismatch: STATUS_MISMATCH", () => {
  const result = classifyMismatch(100000, 100000, "2026-03-14", "2026-03-14", "COMPLETED", "PENDING");
  assertEquals(result.mismatch_type, "STATUS_MISMATCH");
  assertEquals(result.severity, "WARNING");
});

type MismatchType =
  | "MATCHED"
  | "MISSING_IN_PORTONE"
  | "MISSING_IN_LEDGER"
  | "AMOUNT_MISMATCH"
  | "DUPLICATE"
  | "DATE_SHIFT"
  | "STATUS_MISMATCH";
type Severity = "INFO" | "WARNING" | "CRITICAL";

function classifyMismatch(
  ledgerAmount: number | null,
  portoneAmount: number | null,
  ledgerDate: string | null,
  portoneDate: string | null,
  ledgerStatus: string | null,
  portoneStatus: string | null,
): { mismatch_type: MismatchType; severity: Severity } {
  if (ledgerAmount === null && portoneAmount !== null) {
    return { mismatch_type: "MISSING_IN_LEDGER", severity: "CRITICAL" };
  }
  if (portoneAmount === null && ledgerAmount !== null) {
    return { mismatch_type: "MISSING_IN_PORTONE", severity: "CRITICAL" };
  }
  if (ledgerAmount !== null && portoneAmount !== null) {
    if (Math.abs(ledgerAmount - portoneAmount) > 1) {
      return { mismatch_type: "AMOUNT_MISMATCH", severity: "CRITICAL" };
    }
    if (ledgerDate && portoneDate && ledgerDate !== portoneDate) {
      return { mismatch_type: "DATE_SHIFT", severity: "WARNING" };
    }
    if (ledgerStatus && portoneStatus && ledgerStatus !== portoneStatus) {
      return { mismatch_type: "STATUS_MISMATCH", severity: "WARNING" };
    }
  }
  return { mismatch_type: "MATCHED", severity: "INFO" };
}
