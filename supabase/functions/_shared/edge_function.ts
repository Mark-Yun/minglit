/**
 * minglitEdgeFunction — 모든 EF 의 단일 진입점 wrapper.
 *
 * 책임:
 *  - fnName 자동 감지 (Deno.mainModule)
 *  - auth-manifest.json 정책 lookup
 *  - 환경 가드 (ENVIRONMENT ∈ policy.envs)
 *  - Caller 검증 (system / user / external / public)
 *  - Sentry init + error 캡처
 *  - EFContext 조립 (lazy supabase / logger)
 *
 * 자세한 설계: docs/architecture/edge-function-auth.md
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import { createServiceClient } from "./supabase_client.ts";
import { corsResponse, errorResponse } from "./response_utils.ts";
import { initSentry, captureException, log as axiomLog, flush as axiomFlush } from "./logger.ts";
import authManifest from "../auth-manifest.json" with { type: "json" };

// --------------------------------------------------------------------------
// Public types
// --------------------------------------------------------------------------

export type Caller = "system" | "user" | "external" | "public";
export type Environment = "local" | "development" | "dev" | "production";

export type AuthContext =
  | { type: "system" }
  | { type: "user"; userId: string }
  | { type: "external"; reason: string }
  | { type: "public" };

export interface EFContext {
  readonly auth: AuthContext;
  readonly fnName: string;
  readonly env: Environment;
  readonly requestId: string;
  readonly supabase: SupabaseClient;
}

// Discriminated union — manifest schema §3.4
export type ExternalAuth =
  | { type: "ip_allowlist"; ips: string[] }
  | {
      type: "hmac";
      /** Deno env var name that holds the HMAC secret */
      secret_env: string;
      /** Request header carrying the signature (e.g. "x-portone-signature-v2") */
      header: string;
    }
  | {
      type: "custom";
      /** Path to an auth checker module, relative to the EF directory.
       *  The module must export `check(req: Request): Promise<{ok:true;reason:string}|{ok:false}>`.
       */
      module: string;
    };

/** Interface that a `custom` external_auth module must satisfy. */
export interface CustomAuthChecker {
  check(req: Request): Promise<{ ok: true; reason: string } | { ok: false }>;
}

export interface EFPolicy {
  callers: Caller[];
  envs: Environment[];
  external_auth?: ExternalAuth;
  /**
   * ISO date string (e.g. "2026-12-01") — if set, every response from this EF
   * will carry `Deprecation` and `Sunset` headers (RFC 8594) so clients can
   * detect the upcoming EOL without reading documentation.
   */
  deprecated?: string;
  description?: string;
}

export interface MinglitEFOptions {
  /**
   * fnName override. 기본값: Deno.mainModule 에서 자동 감지.
   * 테스트 환경에서 mainModule 이 EF 디렉토리를 가리키지 않을 때 명시적으로 설정.
   */
  fnName?: string;
}

export type EFHandler = (req: Request, ctx: EFContext) => Promise<Response>;

// --------------------------------------------------------------------------
// Startup-time helpers (모듈 로드 시 1회 실행)
// --------------------------------------------------------------------------

function detectFnName(opts: MinglitEFOptions): string {
  // 1. Explicit opts override (rare — for tests that import EF directly)
  if (opts.fnName) return opts.fnName;
  // 2. Test escape hatch — env var set in test file before import
  const testOverride = Deno.env.get("MINGLIT_EF_TEST_FN_NAME");
  if (testOverride) return testOverride;
  // 3. Production — auto-detect from Deno.mainModule
  const main = Deno.mainModule;
  const m = main.match(/\/functions\/([^/]+)\/index\.ts$/);
  if (m) return m[1];
  throw new Error(
    `[minglitEdgeFunction] Cannot detect EF name from Deno.mainModule=${main}. ` +
    `Set MINGLIT_EF_TEST_FN_NAME env var or pass opts.fnName.`,
  );
}

function loadPolicy(fnName: string): EFPolicy {
  const policy = (authManifest.functions as Record<string, EFPolicy>)[fnName];
  if (!policy) {
    throw new Error(
      `[minglitEdgeFunction] auth-manifest.json missing entry for '${fnName}'. ` +
      `Add it before deploy.`,
    );
  }
  return policy;
}

function readEnvironment(): Environment {
  const env = Deno.env.get("ENVIRONMENT");
  if (!env) {
    throw new Error(
      `[minglitEdgeFunction] ENVIRONMENT env var not set. ` +
      `Required for env gate. Check supabase secrets set ENVIRONMENT=...`,
    );
  }
  // Normalize 'development' alias of 'dev'
  return env as Environment;
}

// --------------------------------------------------------------------------
// Per-request helpers
// --------------------------------------------------------------------------

/**
 * Injects RFC 8594 `Deprecation` and `Sunset` response headers.
 * Exported for unit testing; not part of the stable public API.
 *
 * @param res        Original handler response.
 * @param deprecated ISO date string from the manifest (e.g. "2026-12-01").
 * @returns          New Response with the deprecation headers added.
 */
export function addDeprecationHeaders(res: Response, deprecated: string): Response {
  const date = new Date(deprecated);
  if (Number.isNaN(date.getTime())) return res;
  const httpDate = date.toUTCString();
  const headers = new Headers(res.headers);
  // RFC 8594 §2 — Deprecation header: date-tagged form "@<HTTP-date>"
  headers.set("Deprecation", `@${httpDate}`);
  // RFC 8594 §3 — Sunset header: the point at which the resource is removed
  headers.set("Sunset", httpDate);
  return new Response(res.body, { status: res.status, statusText: res.statusText, headers });
}

/**
 * Verifies external caller auth per the manifest's `external_auth` policy.
 * Exported for unit testing; not part of the stable public API.
 *
 * @param req     Incoming request (body is NOT consumed — uses req.clone() for HMAC).
 * @param external Parsed external_auth entry from the manifest.
 * @param fnName  EF name, used to resolve relative `custom` module paths.
 */
export async function checkExternalAuth(
  req: Request,
  external: ExternalAuth,
  fnName: string,
): Promise<{ ok: true; reason: string } | { ok: false }> {
  switch (external.type) {
    case "ip_allowlist": {
      // Fix #1892 H2 패턴: x-real-ip > cf-connecting-ip > x-forwarded-for rightmost
      const realIp = req.headers.get("x-real-ip");
      const cfIp = req.headers.get("cf-connecting-ip");
      const xff = req.headers.get("x-forwarded-for");
      const xffRightmost = xff ? xff.split(",").map(s => s.trim()).pop() : null;
      const clientIp = realIp || cfIp || xffRightmost;
      if (clientIp && external.ips.includes(clientIp)) {
        return { ok: true, reason: `ip_allowlist:${clientIp}` };
      }
      return { ok: false };
    }

    case "hmac": {
      // Verify HMAC-SHA256 signature without consuming the original request body.
      const signature = req.headers.get(external.header);
      if (!signature) return { ok: false };

      const secret = Deno.env.get(external.secret_env);
      if (!secret) return { ok: false };

      const body = await req.clone().text();
      // Fix #2336: import key for "verify" to use crypto.subtle.verify — constant-time
      // comparison (CWE-208: string === is not timing-safe).
      const key = await crypto.subtle.importKey(
        "raw",
        new TextEncoder().encode(secret),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["verify"],
      );

      // Accept both "<hex>" and "sha256=<hex>" formats (PortOne V2 uses the prefixed form).
      const sigHex = signature.startsWith("sha256=") ? signature.slice(7) : signature;
      // Reject odd-length or non-hex chars before decoding. parseInt("aZ",16) silently
      // stops at "Z" returning 10, so a regex guard is required to reject malformed input.
      if (sigHex.length % 2 !== 0 || !/^[0-9a-fA-F]+$/.test(sigHex)) return { ok: false };
      const sigBytes = new Uint8Array(sigHex.length / 2);
      for (let i = 0; i < sigHex.length; i += 2) {
        sigBytes[i / 2] = parseInt(sigHex.slice(i, i + 2), 16);
      }

      // crypto.subtle.verify performs constant-time HMAC comparison internally.
      const valid = await crypto.subtle.verify("HMAC", key, sigBytes, new TextEncoder().encode(body));
      if (valid) {
        return { ok: true, reason: `hmac:${external.header}` };
      }
      return { ok: false };
    }

    case "custom": {
      // Resolve path relative to this EF's directory (escape hatch for bespoke auth).
      const moduleUrl = new URL(external.module, new URL(`../${fnName}/`, import.meta.url));
      const mod = await import(moduleUrl.href) as CustomAuthChecker;
      return await mod.check(req);
    }
  }
}

async function verifyAuth(
  req: Request,
  policy: EFPolicy,
  fnName: string,
): Promise<AuthContext | Response> {
  const allow = (c: Caller) => policy.callers.includes(c);
  const authHeader = req.headers.get("Authorization") ?? "";

  // Bearer 형식 토큰이 있으면 우선 system → user 순으로 검증 (cheap → expensive)
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (allow("system") && serviceKey && token === serviceKey) {
      return { type: "system" };
    }

    if (allow("user")) {
      const supabase = createServiceClient();
      const { data, error } = await supabase.auth.getUser(token);
      if (!error && data.user) {
        return { type: "user", userId: data.user.id };
      }
    }
  }

  // external (Authorization 헤더 무관 — IP / HMAC 등 다른 신호 사용)
  if (allow("external")) {
    if (!policy.external_auth) {
      throw new Error(`[minglitEdgeFunction] policy.callers includes 'external' but external_auth missing`);
    }
    const ext = await checkExternalAuth(req, policy.external_auth, fnName);
    if (ext.ok) return { type: "external", reason: ext.reason };
  }

  if (allow("public")) return { type: "public" };

  // 어떤 caller 도 매칭 안됨
  return errorResponse("Unauthorized", 401);
}

function makeContext(opts: {
  auth: AuthContext;
  fnName: string;
  env: Environment;
  requestId: string;
}): EFContext {
  let _supabase: SupabaseClient | undefined;
  return {
    auth: opts.auth,
    fnName: opts.fnName,
    env: opts.env,
    requestId: opts.requestId,
    get supabase() {
      if (!_supabase) _supabase = createServiceClient();
      return _supabase;
    },
  };
}

// --------------------------------------------------------------------------
// Public API
// --------------------------------------------------------------------------

export function minglitEdgeFunction(handler: EFHandler, opts: MinglitEFOptions = {}): void {
  // Lazy init: try at module load, fall back to first-request retry.
  // Eager init succeeds in production (deploy-time env present).
  // Test env may set required env vars after module import — retry on first request.
  let _ctx: { fnName: string; policy: EFPolicy; env: Environment } | undefined;
  let _initError: Error | undefined;

  function tryInit(): void {
    try {
      const fnName = detectFnName(opts);
      const policy = loadPolicy(fnName);
      const env = readEnvironment();
      initSentry();
      _ctx = { fnName, policy, env };
      _initError = undefined;
    } catch (e) {
      _initError = e instanceof Error ? e : new Error(String(e));
    }
  }

  tryInit();

  Deno.serve(async (req: Request): Promise<Response> => {
    // Retry init if not yet succeeded (test env case)
    if (!_ctx) tryInit();
    if (!_ctx || _initError) {
      const msg = _initError?.message ?? "EF init failed";
      captureException(new Error(`[minglitEdgeFunction] init failed: ${msg}`));
      return errorResponse(`Init failed: ${msg}`, 500);
    }
    const { fnName, policy, env } = _ctx;
    const requestId = crypto.randomUUID();
    axiomLog({ function: fnName, level: "info", message: "invoked", metadata: { method: req.method, requestId } });

    try {
      // CORS preflight
      if (req.method === "OPTIONS") return corsResponse();

      // Env 가드
      if (!policy.envs.includes(env)) {
        return errorResponse(`Function disabled in ${env}`, 403);
      }

      // Auth 검증
      const auth = await verifyAuth(req, policy, fnName);
      if (auth instanceof Response) return auth;

      // Context + handler 호출
      const ctx = makeContext({ auth, fnName, env, requestId });
      let res = await handler(req, ctx);
      if (policy.deprecated) res = addDeprecationHeaders(res, policy.deprecated);
      axiomLog({ function: fnName, level: "info", message: "completed", metadata: { status: res.status, requestId } });
      return res;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      axiomLog({ function: fnName, level: "error", message: msg, metadata: { requestId } });
      captureException(e instanceof Error ? e : new Error(msg));
      return errorResponse("Internal error", 500);
    } finally {
      await axiomFlush();
    }
  });
}
