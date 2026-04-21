// Reads admin.retention_policies, executes cleanup per policy.
// Invoked by pg_cron daily at 03:00 UTC (also manually via workflow_dispatch).
// DB cleanup: admin.delete_old_rows RPC (with schema whitelist).
// Storage cleanup: Supabase Storage API .list() + .remove() in batches.
// pgmq cleanup: admin.archive_old_pgmq_messages RPC.

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BATCH_SIZE = 1000;

// deno-lint-ignore no-explicit-any
function adminDbClient(): SupabaseClient<any, any, any> {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    db: { schema: "admin" },
    auth: { persistSession: false },
  });
}

// deno-lint-ignore no-explicit-any
function publicClient(): SupabaseClient<any, any, any> {
  return createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });
}

async function cleanupDbTable(
  supa: SupabaseClient,
  target: { schema: string; table: string; ts_col: string },
  days: number,
): Promise<number> {
  const { data, error } = await supa.rpc("delete_old_rows", {
    p_schema: target.schema,
    p_table: target.table,
    p_ts_col: target.ts_col,
    p_cutoff_days: days,
  });
  if (error) throw error;
  return typeof data === "number" ? data : 0;
}

async function cleanupStorageBucket(
  supa: SupabaseClient,
  bucketId: string,
  days: number,
): Promise<number> {
  const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  let totalDeleted = 0;
  let offset = 0;

  while (true) {
    const { data, error } = await supa.storage
      .from(bucketId)
      .list("", {
        limit: BATCH_SIZE,
        offset,
        sortBy: { column: "created_at", order: "asc" },
      });
    if (error) throw error;
    if (!data || data.length === 0) break;

    const toDelete = data
      .filter((f) => f.created_at && new Date(f.created_at) < cutoff)
      .map((f) => f.name);

    if (toDelete.length === 0) {
      if (data.length < BATCH_SIZE) break;
      offset += BATCH_SIZE;
      continue;
    }

    const { error: rmError } = await supa.storage.from(bucketId).remove(toDelete);
    if (rmError) throw rmError;
    totalDeleted += toDelete.length;

    if (data.length < BATCH_SIZE) break;
  }
  return totalDeleted;
}

async function archivePgmq(
  supa: SupabaseClient,
  queueName: string,
  days: number,
): Promise<number> {
  const { data, error } = await supa.rpc("archive_old_pgmq_messages", {
    p_queue_name: queueName,
    p_cutoff_days: days,
  });
  if (error) throw error;
  return typeof data === "number" ? data : 0;
}

Deno.serve(async (_req) => {
  const startAll = Date.now();
  const admin = adminDbClient();
  const pub = publicClient();

  const { data: policies, error: listError } = await admin
    .from("retention_policies")
    .select("*")
    .eq("enabled", true);

  if (listError) {
    return new Response(JSON.stringify({ error: listError.message }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  const results: Array<{ id: string; deleted?: number; error?: string }> = [];

  for (const p of policies ?? []) {
    const start = Date.now();
    try {
      let rowsDeleted = 0;
      if (p.kind === "db_table") {
        rowsDeleted = await cleanupDbTable(
          admin,
          p.target as { schema: string; table: string; ts_col: string },
          p.retention_days,
        );
      } else if (p.kind === "storage_bucket") {
        rowsDeleted = await cleanupStorageBucket(
          pub,
          (p.target as { bucket_id: string }).bucket_id,
          p.retention_days,
        );
      } else if (p.kind === "pgmq_archive") {
        rowsDeleted = await archivePgmq(
          admin,
          (p.target as { queue_name: string }).queue_name,
          p.retention_days,
        );
      }

      await admin.from("retention_policies").update({
        last_run_at: new Date().toISOString(),
        last_run_duration_ms: Date.now() - start,
        last_run_rows_deleted: rowsDeleted,
        last_run_status: "success",
        last_run_message: null,
      }).eq("id", p.id);

      await admin.from("retention_policy_audit").insert({
        policy_id: p.id,
        action: "run",
        rows_deleted: rowsDeleted,
        duration_ms: Date.now() - start,
      });

      results.push({ id: p.id, deleted: rowsDeleted });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      await admin.from("retention_policies").update({
        last_run_at: new Date().toISOString(),
        last_run_duration_ms: Date.now() - start,
        last_run_status: "error",
        last_run_message: msg,
      }).eq("id", p.id);

      await admin.from("retention_policy_audit").insert({
        policy_id: p.id,
        action: "run",
        duration_ms: Date.now() - start,
        error: msg,
      });

      results.push({ id: p.id, error: msg });
    }
  }

  return new Response(
    JSON.stringify({
      total_duration_ms: Date.now() - startAll,
      results,
    }),
    { headers: { "content-type": "application/json" } },
  );
});
