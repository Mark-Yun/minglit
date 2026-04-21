import { createServiceClient } from "../_shared/supabase_client.ts";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";

initSentry();

type RetentionKind = "db_table" | "storage_bucket" | "pgmq_archive";

interface RetentionPolicy {
  id: string;
  kind: RetentionKind;
  retention_days: number;
  target: Record<string, string>;
}

interface PolicyResult {
  id: string;
  status: "success" | "error" | "skipped";
  rows_deleted: number;
  duration_ms: number;
  error?: string;
}

async function runDbTableCleanup(
  supabase: ReturnType<typeof createServiceClient>,
  policy: RetentionPolicy,
): Promise<{ rows_deleted: number }> {
  const { schema, table, ts_col } = policy.target;
  const { data, error } = await supabase.schema("admin").rpc("delete_old_rows", {
    p_schema: schema,
    p_table: table,
    p_ts_col: ts_col,
    p_cutoff_days: policy.retention_days,
  });
  if (error) throw new Error(error.message);
  return { rows_deleted: Number(data ?? 0) };
}

async function runStorageBucketCleanup(
  supabase: ReturnType<typeof createServiceClient>,
  policy: RetentionPolicy,
): Promise<{ rows_deleted: number }> {
  const { bucket_id, path_prefix = "" } = policy.target;
  const cutoff = new Date(Date.now() - policy.retention_days * 86400 * 1000);

  let deleted = 0;
  let offset = 0;
  const BATCH = 1000;

  while (true) {
    const { data: files, error: listError } = await supabase.storage
      .from(bucket_id)
      .list(path_prefix || undefined, {
        limit: BATCH,
        offset,
        sortBy: { column: "created_at", order: "asc" },
      });
    if (listError) throw new Error(listError.message);
    if (!files || files.length === 0) break;

    const stale = files
      .filter((f) => f.created_at && new Date(f.created_at) < cutoff)
      .map((f) => (path_prefix ? `${path_prefix}/${f.name}` : f.name));

    if (stale.length > 0) {
      const { error: removeError } = await supabase.storage
        .from(bucket_id)
        .remove(stale);
      if (removeError) throw new Error(removeError.message);
      deleted += stale.length;
    }

    if (files.length < BATCH) break;
    offset += BATCH;
  }

  return { rows_deleted: deleted };
}

async function runPgmqArchiveCleanup(
  supabase: ReturnType<typeof createServiceClient>,
  policy: RetentionPolicy,
): Promise<{ rows_deleted: number }> {
  const { queue_name } = policy.target;
  const { data, error } = await supabase.schema("admin").rpc("archive_old_pgmq_messages", {
    p_queue_name: queue_name,
    p_cutoff_days: policy.retention_days,
  });
  if (error) throw new Error(error.message);
  return { rows_deleted: Number(data ?? 0) };
}

async function runPolicy(
  supabase: ReturnType<typeof createServiceClient>,
  policy: RetentionPolicy,
): Promise<PolicyResult> {
  const start = Date.now();
  try {
    let result: { rows_deleted: number };
    if (policy.kind === "db_table") {
      result = await runDbTableCleanup(supabase, policy);
    } else if (policy.kind === "storage_bucket") {
      result = await runStorageBucketCleanup(supabase, policy);
    } else {
      result = await runPgmqArchiveCleanup(supabase, policy);
    }
    const duration_ms = Date.now() - start;
    return { id: policy.id, status: "success", rows_deleted: result.rows_deleted, duration_ms };
  } catch (e) {
    const duration_ms = Date.now() - start;
    return {
      id: policy.id,
      status: "error",
      rows_deleted: 0,
      duration_ms,
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

async function updatePolicyRunResult(
  supabase: ReturnType<typeof createServiceClient>,
  result: PolicyResult,
): Promise<void> {
  const now = new Date().toISOString();

  await supabase
    .schema("admin")
    .from("retention_policies")
    .update({
      last_run_at: now,
      last_run_duration_ms: result.duration_ms,
      last_run_rows_deleted: result.rows_deleted,
      last_run_status: result.status,
      last_run_message: result.error ?? null,
    })
    .eq("id", result.id);

  await supabase
    .schema("admin")
    .from("retention_policy_audit")
    .insert({
      policy_id: result.id,
      action: "run",
      rows_deleted: result.rows_deleted,
      duration_ms: result.duration_ms,
      error: result.error ?? null,
    });
}

Deno.serve(withHandler(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const supabase = createServiceClient();
  const totalStart = Date.now();

  const { data: policies, error: fetchError } = await supabase
    .schema("admin")
    .from("retention_policies")
    .select("id, kind, retention_days, target")
    .eq("enabled", true);

  if (fetchError) {
    return errorResponse(`Failed to fetch retention policies: ${fetchError.message}`, 500);
  }

  if (!policies || policies.length === 0) {
    return successResponse({ total_duration_ms: Date.now() - totalStart, results: [] });
  }

  const results = await Promise.all(
    (policies as RetentionPolicy[]).map((p) => runPolicy(supabase, p)),
  );

  await Promise.all(results.map((r) => updatePolicyRunResult(supabase, r)));

  return successResponse({
    total_duration_ms: Date.now() - totalStart,
    results: results.map((r) => ({
      id: r.id,
      status: r.status,
      rows_deleted: r.rows_deleted,
      duration_ms: r.duration_ms,
      ...(r.error ? { error: r.error } : {}),
    })),
  });
}));
