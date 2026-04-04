import { successResponse, errorResponse } from "../_shared/response_utils.ts";
import { initSentry, withHandler } from "../_shared/logger.ts";
import { checkAllFunctions } from "../_shared/env_keystore.ts";
import { nowISO } from "../_shared/temporal_utils.ts";

initSentry();

interface CheckResult {
  status: "up" | "down";
  latency_ms: number;
  error?: string;
}

const TIMEOUT_MS = 5000;

async function withTimeout<T>(
  fn: () => Promise<T>,
  timeoutMs: number,
): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fn();
  } finally {
    clearTimeout(timer);
  }
}

async function checkDatabase(): Promise<CheckResult> {
  const start = performance.now();
  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const res = await withTimeout(
      () =>
        fetch(`${url}/rest/v1/`, {
          method: "HEAD",
          headers: {
            apikey: key,
            Authorization: `Bearer ${key}`,
          },
        }),
      TIMEOUT_MS,
    );

    const latency = Math.round(performance.now() - start);
    return res.ok
      ? { status: "up", latency_ms: latency }
      : { status: "down", latency_ms: latency, error: `HTTP ${res.status}` };
  } catch (e) {
    return {
      status: "down",
      latency_ms: Math.round(performance.now() - start),
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

async function checkAuth(): Promise<CheckResult> {
  const start = performance.now();
  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    const res = await withTimeout(
      () => fetch(`${url}/auth/v1/health`, {
        headers: { apikey: key },
      }),
      TIMEOUT_MS,
    );

    const latency = Math.round(performance.now() - start);
    return res.ok
      ? { status: "up", latency_ms: latency }
      : { status: "down", latency_ms: latency, error: `HTTP ${res.status}` };
  } catch (e) {
    return {
      status: "down",
      latency_ms: Math.round(performance.now() - start),
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

async function checkStorage(): Promise<CheckResult> {
  const start = performance.now();
  try {
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const res = await withTimeout(
      () =>
        fetch(`${url}/storage/v1/bucket`, {
          headers: {
            apikey: key,
            Authorization: `Bearer ${key}`,
          },
        }),
      TIMEOUT_MS,
    );

    const latency = Math.round(performance.now() - start);
    return res.ok
      ? { status: "up", latency_ms: latency }
      : { status: "down", latency_ms: latency, error: `HTTP ${res.status}` };
  } catch (e) {
    return {
      status: "down",
      latency_ms: Math.round(performance.now() - start),
      error: e instanceof Error ? e.message : String(e),
    };
  }
}

Deno.serve(withHandler(async (req) => {
  if (req.method !== "GET") {
    return errorResponse("Method not allowed", 405);
  }

  const url = new URL(req.url);
  const includeEnv = url.searchParams.get("env") === "true";

  const [database, auth, storage] = await Promise.all([
    checkDatabase(),
    checkAuth(),
    checkStorage(),
  ]);

  const allUp =
    database.status === "up" &&
    auth.status === "up" &&
    storage.status === "up";

  const body: Record<string, unknown> = {
    status: allUp ? "healthy" : "unhealthy",
    timestamp: nowISO(),
    checks: {
      database: { status: database.status, latency_ms: database.latency_ms, ...(database.error && { error: database.error }) },
      auth: { status: auth.status, latency_ms: auth.latency_ms, ...(auth.error && { error: auth.error }) },
      storage: { status: storage.status, latency_ms: storage.latency_ms, ...(storage.error && { error: storage.error }) },
    },
  };

  // env-check: report missing env vars per function (key names only, no values)
  if (includeEnv) {
    const missingByFunction = checkAllFunctions();
    const totalMissing = Object.values(missingByFunction).flat().length;
    body.env_check = {
      status: totalMissing === 0 ? "ok" : "missing",
      total_missing: totalMissing,
      by_function: missingByFunction,
    };
  }

  if (allUp) {
    return successResponse(body, 200);
  }
  return errorResponse("unhealthy", 503, body);
}));
