/**
 * Sentry error tracking + Axiom structured logging for Edge Functions.
 *
 * Supports both `serve()` (old) and `Deno.serve()` (new) patterns.
 * Gracefully no-ops when SENTRY_DSN / AXIOM_API_TOKEN is not set.
 */

import { log as axiomLog, flush as axiomFlush, extractFunctionName } from "./axiom_logger.ts";
export { log, flush } from "./axiom_logger.ts";

let _initialized = false;
let _enabled = false;

// Dynamic Sentry module reference (loaded only when DSN is present)
let _Sentry: {
  init: (options: Record<string, unknown>) => void;
  captureException: (error: unknown) => void;
  flush: (timeout: number) => Promise<boolean>;
  startSpan: (options: { name: string; op: string }, fn: () => Promise<unknown>) => Promise<unknown>;
} | null = null;

/**
 * Initialize Sentry. Call once at module top-level, before serve().
 * No-ops if SENTRY_DSN env var is missing or empty.
 */
export async function initSentry(dsn?: string): Promise<void> {
  if (_initialized) return;
  _initialized = true;

  const sentryDsn = dsn ?? Deno.env.get("SENTRY_DSN") ?? "";
  if (!sentryDsn) {
    _enabled = false;
    return;
  }

  try {
    const Sentry = await import("npm:@sentry/node");
    Sentry.init({
      dsn: sentryDsn,
      environment: Deno.env.get("ENVIRONMENT") ?? "local",
      tracesSampleRate: 0.2,
      defaultIntegrations: false,
    });
    _Sentry = Sentry;
    _enabled = true;
  } catch (e) {
    console.warn("[sentry_utils] Failed to initialize Sentry:", e);
    _enabled = false;
  }
}

/**
 * Wrapper for old `serve()` pattern.
 *
 * Usage:
 * ```ts
 * import { initSentry, withSentry } from "../_shared/sentry_utils.ts";
 * initSentry();
 * serve(withSentry(async (req) => { ... }));
 * ```
 */
export function withSentry(
  handler: (req: Request) => Response | Promise<Response>,
): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    const fn = extractFunctionName(req);
    axiomLog({ function: fn, level: "info", message: "invoked", metadata: { method: req.method } });
    try {
      const res = await handler(req);
      axiomLog({ function: fn, level: "info", message: "completed", metadata: { status: res.status } });
      return res;
    } catch (error) {
      axiomLog({ function: fn, level: "error", message: error instanceof Error ? error.message : String(error) });
      if (_enabled && _Sentry) {
        _Sentry.captureException(error);
        await _Sentry.flush(2000);
      }
      throw error;
    } finally {
      await axiomFlush();
    }
  };
}

/**
 * Wrapper for new `Deno.serve()` pattern.
 *
 * Usage:
 * ```ts
 * import { initSentry, withSentryHandler } from "../_shared/sentry_utils.ts";
 * await initSentry();
 * Deno.serve(withSentryHandler(async (req) => { ... }));
 * ```
 */
export function withSentryHandler(
  handler: (req: Request) => Response | Promise<Response>,
): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    const fn = extractFunctionName(req);
    axiomLog({ function: fn, level: "info", message: "invoked", metadata: { method: req.method } });
    try {
      const res = await handler(req);
      axiomLog({ function: fn, level: "info", message: "completed", metadata: { status: res.status } });
      return res;
    } catch (error) {
      axiomLog({ function: fn, level: "error", message: error instanceof Error ? error.message : String(error) });
      if (_enabled && _Sentry) {
        _Sentry.captureException(error);
        await _Sentry.flush(2000);
      }
      throw error;
    } finally {
      await axiomFlush();
    }
  };
}

/**
 * Wrap an async operation in a Sentry performance span.
 * No-ops if Sentry is not initialized.
 *
 * Usage:
 * ```ts
 * const result = await withSpan(
 *   'db.query.users',
 *   'db.query',
 *   () => supabase.from('users').select('*')
 * );
 * ```
 */
export async function withSpan<T>(
  name: string,
  operation: string,
  fn: () => Promise<T>,
): Promise<T> {
  if (!_enabled || !_Sentry) return fn();

  try {
    return await _Sentry.startSpan({ name, op: operation }, fn) as T;
  } catch (error) {
    throw error;
  }
}

/** Reset internal state. For testing only. */
export function _resetForTesting(): void {
  _initialized = false;
  _enabled = false;
  _Sentry = null;
}
