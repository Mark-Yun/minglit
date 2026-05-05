import type { SupabaseClient } from "@supabase/supabase-js";
import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";
import { captureException } from "../_shared/logger.ts";

type RetentionKind = "db_table" | "storage_bucket" | "pgmq_archive" | "db_custom_fn";

interface RetentionPolicy {
  id: string;
  kind: RetentionKind;
  retention_days: number;
  target: Record<string, string> & { use_absolute_ts?: boolean; fn?: string };
  metadata: Record<string, unknown>;
}

interface PolicyResult {
  id: string;
  status: "success" | "error" | "skipped";
  rows_deleted: number;
  duration_ms: number;
  error?: string;
}

async function runDbTableCleanup(
  supabase: SupabaseClient,
  policy: RetentionPolicy,
): Promise<{ rows_deleted: number }> {
  const { schema, table, ts_col, use_absolute_ts } = policy.target as unknown as { schema: string; table: string; ts_col: string; use_absolute_ts?: boolean };
  if (use_absolute_ts) {
    const { data, error } = await supabase.schema("admin").rpc("delete_expired_rows", {
      p_schema: schema,
      p_table: table,
      p_ts_col: ts_col,
    });
    if (error) throw new Error(error.message);
    return { rows_deleted: Number(data ?? 0) };
  }
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
  supabase: SupabaseClient,
  policy: RetentionPolicy,
): Promise<{ rows_deleted: number }> {
  // Fix #2204: 옛 패턴 (supabase.storage.from(b).list(prefix)) 은 sub-directory 안 들여다 봄.
  // 모든 파일이 sub-dir 에 있으면 stale=0 으로 잘못 판단. admin.find_stale_storage_objects()
  // 가 storage.objects 직접 query 로 평면화된 모든 stale 파일 반환 → 재귀 무관.
  const { bucket_id, path_prefix = "" } = policy.target;
  const REMOVE_BATCH = 100;  // Supabase storage remove API batch limit
  const QUERY_BATCH = 10000;  // admin function 의 LIMIT

  let deleted = 0;

  while (true) {
    const { data: staleFiles, error: queryError } = await supabase
      .schema("admin")
      .rpc("find_stale_storage_objects", {
        p_bucket_id: bucket_id,
        p_path_prefix: path_prefix,
        p_cutoff_days: policy.retention_days,
        p_limit: QUERY_BATCH,
      });
    if (queryError) throw new Error(queryError.message);
    if (!staleFiles || staleFiles.length === 0) break;

    const names = (staleFiles as Array<{ name: string }>).map((f) => f.name);

    // Storage API batch 단위로 삭제 (한번에 너무 많이 보내면 timeout)
    for (let i = 0; i < names.length; i += REMOVE_BATCH) {
      const batch = names.slice(i, i + REMOVE_BATCH);
      const { error: removeError } = await supabase.storage
        .from(bucket_id)
        .remove(batch);
      if (removeError) throw new Error(removeError.message);
      deleted += batch.length;
    }

    // 한 번에 QUERY_BATCH 미만 받으면 더 없는 거 — 종료
    if (staleFiles.length < QUERY_BATCH) break;
  }

  return { rows_deleted: deleted };
}

async function runPgmqArchiveCleanup(
  supabase: SupabaseClient,
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

// db_custom_fn: JOIN-based or complex operations that cannot be expressed as a simple ts_col comparison.
// target.fn must be a fully-qualified admin-schema function name (e.g. "admin.anonymize_old_event_participants")
// that accepts a single p_cutoff_days int parameter and returns bigint (rows affected).
async function runDbCustomFnCleanup(
  supabase: SupabaseClient,
  policy: RetentionPolicy,
): Promise<{ rows_deleted: number }> {
  const { fn } = policy.target;
  if (!fn) throw new Error(`db_custom_fn policy '${policy.id}' missing target.fn`);
  const fnName = fn.includes(".") ? fn.split(".").pop()! : fn;
  const { data, error } = await supabase.schema("admin").rpc(fnName, {
    p_cutoff_days: policy.retention_days,
  });
  if (error) throw new Error(error.message);
  return { rows_deleted: Number(data ?? 0) };
}

async function runPolicy(
  supabase: SupabaseClient,
  policy: RetentionPolicy,
): Promise<PolicyResult> {
  const start = Date.now();
  if (policy.metadata?.skip_cleanup === true) {
    return { id: policy.id, status: "skipped", rows_deleted: 0, duration_ms: 0 };
  }
  try {
    let result: { rows_deleted: number };
    if (policy.kind === "db_table") {
      result = await runDbTableCleanup(supabase, policy);
    } else if (policy.kind === "storage_bucket") {
      result = await runStorageBucketCleanup(supabase, policy);
    } else if (policy.kind === "db_custom_fn") {
      result = await runDbCustomFnCleanup(supabase, policy);
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
  supabase: SupabaseClient,
  result: PolicyResult,
): Promise<void> {
  const now = new Date().toISOString();

  const { error: updateError } = await supabase
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

  if (updateError) captureException(new Error(`retention_policies update failed [${result.id}]: ${updateError.message}`));

  const { error: auditError } = await supabase
    .schema("admin")
    .from("retention_policy_audit")
    .insert({
      policy_id: result.id,
      action: "run",
      rows_deleted: result.rows_deleted,
      duration_ms: result.duration_ms,
      error: result.error ?? null,
    });

  if (auditError) captureException(new Error(`retention_policy_audit insert failed [${result.id}]: ${auditError.message}`));
}

export const handler = async (req: Request, { supabase }: EFContext): Promise<Response> => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const totalStart = Date.now();

  const { data: policies, error: fetchError } = await supabase
    .schema("admin")
    .from("retention_policies")
    .select("id, kind, retention_days, target, metadata")
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
};

minglitEdgeFunction(handler);
