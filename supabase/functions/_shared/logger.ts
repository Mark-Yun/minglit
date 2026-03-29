/**
 * Unified observability for Edge Functions.
 *
 * - Axiom: structured logging (all levels)
 * - Sentry: error tracking + performance spans
 *
 * Usage:
 * ```ts
 * import { initSentry, withHandler, log, withSpan } from "../_shared/logger.ts";
 * await initSentry();
 * Deno.serve(withHandler(async (req) => {
 *   log({ function: "my-fn", level: "info", message: "doing work" });
 *   const data = await withSpan("db.query", "db", () => supabase.from("t").select("*"));
 *   return successResponse(data);
 * }));
 * ```
 *
 * Gracefully no-ops when SENTRY_DSN / AXIOM_API_TOKEN is not set.
 */

import { log as axiomLog, flush as axiomFlush, extractFunctionName } from "./axiom_logger.ts";
// Fix #763: Sentry beforeSend PII 필터링
import { maskPii } from "./pii_masker.ts";
export { log, flush, isEnabled, debugStatus } from "./axiom_logger.ts";

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
 * Initialize Sentry. Call once at module top-level, before Deno.serve().
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
      // Fix #763: Sentry 전송 전 PII가 포함되는 섹션만 선택적으로 마스킹.
      // 전체 이벤트 마스킹은 "name" 등 일반 필드명이 Sentry 구조적 필드
      // (exception type, breadcrumb category)와 충돌하여 디버깅 정보 손실 가능.
      // deno-lint-ignore no-explicit-any
      beforeSend(event: any) {
        if (event.user) event.user = maskPii(event.user);
        if (event.extra) event.extra = maskPii(event.extra);
        if (event.contexts) event.contexts = maskPii(event.contexts);
        return event;
      },
    });
    _Sentry = Sentry;
    _enabled = true;
  } catch (e) {
    console.warn("[logger] Failed to initialize Sentry:", e);
    _enabled = false;
  }
}

/**
 * Request handler wrapper. Provides:
 * - Axiom structured logging (invoked/completed/error)
 * - Sentry error capture
 * - Axiom flush on completion
 *
 * Works with both `Deno.serve()` and legacy `serve()`.
 */
export function withHandler(
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

/** @deprecated Use `withHandler` instead. */
export const withSentry = withHandler;
/** @deprecated Use `withHandler` instead. */
export const withSentryHandler = withHandler;

/**
 * Wrap an async operation in a Sentry performance span.
 * No-ops if Sentry is not initialized.
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
