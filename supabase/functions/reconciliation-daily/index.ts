import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PortoneV2Client } from "../_shared/portone_client.ts";

const PORTONE_V2_API_KEY = Deno.env.get("PORTONE_V2_API_KEY") ?? "";

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

interface PortoneSettlement {
  id: string;
  partnerId?: string;
  amount?: { total?: number };
  settledAt?: string;
  status?: string;
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: { "Access-Control-Allow-Origin": "*" } });
  }

  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!authHeader || authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    serviceRoleKey,
  );

  const yesterday = new Date();
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const runDate = yesterday.toISOString().split("T")[0];

  const { data: runRecord, error: runInsertError } = await supabase
    .from("reconciliation_runs")
    .insert({ run_date: runDate, run_type: "DAILY", status: "RUNNING" })
    .select("id")
    .single();

  if (runInsertError || !runRecord) {
    return new Response(
      JSON.stringify({ error: "Failed to create run", detail: runInsertError?.message }),
      { status: 500 },
    );
  }

  const runId = runRecord.id;

  try {
    const { data: ledgerItems, error: ledgerError } = await supabase
      .from("settlement_items")
      .select("id, partner_id, net_amount, processing_ended_at, status, payout_id")
      .eq("status", "COMPLETED")
      .gte("processing_ended_at", `${runDate}T00:00:00.000Z`)
      .lt("processing_ended_at", `${runDate}T23:59:59.999Z`);

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
        { status: 500 },
      );
    }

    const sourceHash = computeSourceHash(ledgerItems ?? [], portoneSettlements);

    const portoneMap = new Map<string, PortoneSettlement>();
    const portonePartnerIdMap = new Map<string, PortoneSettlement[]>();

    for (const ps of portoneSettlements) {
      portoneMap.set(ps.id, ps);
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
      const portoneMatch = portoneMatches.find(
        (ps) => Math.abs((ps.amount?.total ?? 0) - item.net_amount) <= 1,
      );

      if (portoneMatch) {
        matchedPortoneIds.add(portoneMatch.id);
        const portoneDate = portoneMatch.settledAt?.split("T")[0] ?? null;
        const ledgerDate = item.processing_ended_at?.split("T")[0] ?? null;
        const { mismatch_type, severity } = classifyMismatch(
          item.net_amount,
          portoneMatch.amount?.total ?? null,
          ledgerDate,
          portoneDate,
          item.status,
          portoneMatch.status ?? null,
        );
        results.push({
          settlement_item_id: item.id,
          portone_settlement_id: portoneMatch.id,
          mismatch_type,
          severity,
          details: {
            ledger_amount: item.net_amount,
            portone_amount: portoneMatch.amount?.total,
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
      if (!matchedPortoneIds.has(ps.id)) {
        results.push({
          settlement_item_id: null,
          portone_settlement_id: ps.id,
          mismatch_type: MISMATCH_TYPES.MISSING_IN_LEDGER,
          severity: "CRITICAL",
          details: { portone_amount: ps.amount?.total, partner_id: ps.partnerId },
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
    if (rpcError) console.error("Kill switch RPC error:", rpcError.message);

    const matchedCount = results.filter((r) => r.mismatch_type === MISMATCH_TYPES.MATCHED).length;
    const mismatchedCount = results.filter((r) => r.mismatch_type !== MISMATCH_TYPES.MATCHED).length;
    const criticalCount = results.filter((r) => r.severity === "CRITICAL").length;

    await supabase
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

    return new Response(
      JSON.stringify({
        run_id: runId,
        run_date: runDate,
        total: results.length,
        matched: matchedCount,
        mismatched: mismatchedCount,
        critical: criticalCount,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
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
      { status: 500 },
    );
  }
});
