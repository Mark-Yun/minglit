// Fix #179: esm.sh 직접 URL → deno.json import map 기반으로 통일
import { createServiceClient } from "../_shared/supabase_client.ts";
import { PortoneV2Client, PortoneSettlement } from "../_shared/portone_client.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";

await initSentry();

const PORTONE_V2_API_KEY = Deno.env.get("PORTONE_V2_API_KEY") ?? "";

if (!PORTONE_V2_API_KEY) {
  throw new Error("Missing required environment variable: PORTONE_V2_API_KEY");
}

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
};

const MISMATCH_TYPES = {
  MATCHED: "MATCHED",
  MISSING_IN_PORTONE: "MISSING_IN_PORTONE",
  MISSING_IN_LEDGER: "MISSING_IN_LEDGER",
  AMOUNT_MISMATCH: "AMOUNT_MISMATCH",
  DUPLICATE: "DUPLICATE",
  DATE_SHIFT: "DATE_SHIFT",
  STATUS_MISMATCH: "STATUS_MISMATCH",
} as const;

type MismatchType = typeof MISMATCH_TYPES[keyof typeof MISMATCH_TYPES];
type Severity = "INFO" | "WARNING" | "CRITICAL";

interface LedgerItem {
  id: string;
  partner_id: string;
  net_amount: number;
  processing_ended_at: string;
  status: string;
  payout_id: string | null;
}

interface ReconciliationResult {
  settlement_item_id: string | null;
  portone_settlement_id: string | null;
  mismatch_type: MismatchType;
  severity: Severity;
  details: Record<string, unknown>;
}

function classifyMismatch(
  ledgerAmount: number | null,
  portoneAmount: number | null,
  ledgerDate: string | null,
  portoneDate: string | null,
  ledgerStatus: string | null,
  portoneStatus: string | null,
): { mismatch_type: MismatchType; severity: Severity } {
  if (ledgerAmount === null && portoneAmount !== null) {
    return { mismatch_type: MISMATCH_TYPES.MISSING_IN_LEDGER, severity: "CRITICAL" };
  }
  if (portoneAmount === null && ledgerAmount !== null) {
    return { mismatch_type: MISMATCH_TYPES.MISSING_IN_PORTONE, severity: "CRITICAL" };
  }
  if (ledgerAmount !== null && portoneAmount !== null) {
    if (Math.abs(ledgerAmount - portoneAmount) > 1) {
      return { mismatch_type: MISMATCH_TYPES.AMOUNT_MISMATCH, severity: "CRITICAL" };
    }
    if (ledgerDate && portoneDate && ledgerDate !== portoneDate) {
      return { mismatch_type: MISMATCH_TYPES.DATE_SHIFT, severity: "WARNING" };
    }
    if (ledgerStatus && portoneStatus && ledgerStatus !== portoneStatus) {
      return { mismatch_type: MISMATCH_TYPES.STATUS_MISMATCH, severity: "WARNING" };
    }
  }
  return { mismatch_type: MISMATCH_TYPES.MATCHED, severity: "INFO" };
}

function computeSourceHash(ledgerData: unknown[], portoneData: unknown[]): string {
  const raw = JSON.stringify({ ledger: ledgerData, portone: portoneData });
  let hash = 0;
  for (let i = 0; i < raw.length; i++) {
    hash = ((hash << 5) - hash) + raw.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash).toString(16);
}

Deno.serve(withHandler(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!authHeader || authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  const supabase = createServiceClient();

  const nowKst = new Date(Date.now() + 9 * 60 * 60 * 1000);
  const yesterdayKst = new Date(nowKst);
  yesterdayKst.setUTCDate(yesterdayKst.getUTCDate() - 1);
  const runDate = yesterdayKst.toISOString().split("T")[0];
  const runDateStart = `${runDate}T00:00:00.000+09:00`;
  const runDateEnd = `${runDate}T23:59:59.999+09:00`;

  const { data: runRecord, error: runInsertError } = await supabase
    .from("reconciliation_runs")
    .insert({ run_date: runDate, run_type: "DAILY", status: "RUNNING" })
    .select("id")
    .single();

  if (runInsertError || !runRecord) {
    return new Response(
      JSON.stringify({ error: "Failed to create run", detail: runInsertError?.message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  const runId = runRecord.id;

  try {
    const { data: ledgerItems, error: ledgerError } = await supabase
      .from("settlement_items")
      .select("id, partner_id, net_amount, processing_ended_at, status, payout_id")
      .eq("status", "COMPLETED")
      .gte("processing_ended_at", runDateStart)
      .lte("processing_ended_at", runDateEnd);

    if (ledgerError) throw new Error(`Ledger query failed: ${ledgerError.message}`);

    const portoneClient = new PortoneV2Client(PORTONE_V2_API_KEY);
    let portoneSettlements: PortoneSettlement[] = [];

    try {
      const portoneResponse = await portoneClient.getPartnerSettlements({
        dateRange: { from: runDate, until: runDate },
      });
      portoneSettlements = (portoneResponse.settlements ?? []) as PortoneSettlement[];
    } catch (portoneErr) {
      await supabase
        .from("reconciliation_runs")
        .update({ status: "FAILED", error_message: String(portoneErr), completed_at: new Date().toISOString() })
        .eq("id", runId);
      return new Response(
        JSON.stringify({ error: "PortOne API failed", detail: String(portoneErr) }),
        { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const sourceHash = computeSourceHash(ledgerItems ?? [], portoneSettlements);

    const portoneMap = new Map<string, PortoneSettlement>();
    const portonePartnerIdMap = new Map<string, PortoneSettlement[]>();

    for (const ps of portoneSettlements) {
      const psId = ps.id ?? "";
      portoneMap.set(psId, ps);
      if (ps.partnerId) {
        const existing = portonePartnerIdMap.get(ps.partnerId) ?? [];
        existing.push(ps);
        portonePartnerIdMap.set(ps.partnerId, existing);
      }
    }

    const results: ReconciliationResult[] = [];
    const matchedPortoneIds = new Set<string>();

    for (const item of (ledgerItems ?? []) as LedgerItem[]) {
      const portoneMatches = portonePartnerIdMap.get(item.partner_id) ?? [];
      const portoneMatch =
        portoneMatches.find(
          (ps) => !matchedPortoneIds.has(ps.id ?? "") && Math.abs((ps.amount ?? 0) - item.net_amount) <= 1,
        ) ??
        portoneMatches.find(
          (ps) => matchedPortoneIds.has(ps.id ?? "") && Math.abs((ps.amount ?? 0) - item.net_amount) <= 1,
        );

      if (portoneMatch) {
        const psId = portoneMatch.id ?? "";
        matchedPortoneIds.add(psId);
        const portoneDate = typeof portoneMatch.settlementDate === "string"
          ? portoneMatch.settlementDate.split("T")[0]
          : null;
        const ledgerDate = item.processing_ended_at?.split("T")[0] ?? null;
        const { mismatch_type, severity } = classifyMismatch(
          item.net_amount,
          portoneMatch.amount ?? null,
          ledgerDate,
          portoneDate,
          item.status,
          typeof portoneMatch.status === "string" ? portoneMatch.status : null,
        );
        results.push({
          settlement_item_id: item.id,
          portone_settlement_id: psId,
          mismatch_type,
          severity,
          details: {
            ledger_amount: item.net_amount,
            portone_amount: portoneMatch.amount,
            ledger_date: ledgerDate,
            portone_date: portoneDate,
          },
        });
      } else {
        results.push({
          settlement_item_id: item.id,
          portone_settlement_id: null,
          mismatch_type: MISMATCH_TYPES.MISSING_IN_PORTONE,
          severity: "CRITICAL",
          details: { ledger_amount: item.net_amount, partner_id: item.partner_id },
        });
      }
    }

    for (const ps of portoneSettlements) {
      const psId = ps.id ?? "";
      if (!matchedPortoneIds.has(psId)) {
        results.push({
          settlement_item_id: null,
          portone_settlement_id: psId,
          mismatch_type: MISMATCH_TYPES.MISSING_IN_LEDGER,
          severity: "CRITICAL",
          details: { portone_amount: ps.amount, partner_id: ps.partnerId },
        });
      }
    }

    const seenPortoneIds = new Set<string>();
    for (const result of results) {
      if (result.portone_settlement_id && matchedPortoneIds.has(result.portone_settlement_id)) {
        if (seenPortoneIds.has(result.portone_settlement_id)) {
          result.mismatch_type = MISMATCH_TYPES.DUPLICATE;
          result.severity = "WARNING";
        } else {
          seenPortoneIds.add(result.portone_settlement_id);
        }
      }
    }

    if (results.length > 0) {
      const resultRows = results.map((r) => ({ ...r, run_id: runId }));
      const { error: insertError } = await supabase
        .from("reconciliation_results")
        .insert(resultRows);
      if (insertError) throw new Error(`Result insert failed: ${insertError.message}`);
    }

    const { error: rpcError } = await supabase.rpc("process_reconciliation_kill_switch", {
      p_run_id: runId,
    });
    if (rpcError) {
      throw new Error(`Kill switch RPC failed: ${rpcError.message}`);
    }

    const matchedCount = results.filter((r) => r.mismatch_type === MISMATCH_TYPES.MATCHED).length;
    const mismatchedCount = results.filter((r) => r.mismatch_type !== MISMATCH_TYPES.MATCHED).length;
    const criticalCount = results.filter((r) => r.severity === "CRITICAL").length;

    const { error: completeError } = await supabase
      .from("reconciliation_runs")
      .update({
        status: "COMPLETED",
        source_hash: sourceHash,
        total_count: results.length,
        matched_count: matchedCount,
        mismatched_count: mismatchedCount,
        critical_count: criticalCount,
        completed_at: new Date().toISOString(),
      })
      .eq("id", runId);

    if (completeError) {
      throw new Error(`Failed to mark run as COMPLETED: ${completeError.message}`);
    }

    return new Response(
      JSON.stringify({
        run_id: runId,
        run_date: runDate,
        total: results.length,
        matched: matchedCount,
        mismatched: mismatchedCount,
        critical: criticalCount,
      }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  } catch (err) {
    await supabase
      .from("reconciliation_runs")
      .update({
        status: "FAILED",
        error_message: String(err),
        completed_at: new Date().toISOString(),
      })
      .eq("id", runId);
    return new Response(
      JSON.stringify({ error: "Reconciliation failed", detail: String(err) }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
}));
