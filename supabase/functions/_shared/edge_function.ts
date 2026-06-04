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
import {
  createServiceClient,
  getLegacyServiceRoleJwt,
  getSupabaseSecretApiKeys,
} from "./supabase_client.ts";
import { corsHeaders, corsResponse, errorResponse } from "./response_utils.ts";
import { parseJsonBody } from "./request_utils.ts";
import {
  captureException,
  flush as axiomFlush,
  initSentry,
  log as axiomLog,
} from "./logger.ts";
import authManifest from "../auth-manifest.json" with { type: "json" };

// --------------------------------------------------------------------------
// Public types
// --------------------------------------------------------------------------

export type Caller = "system" | "user" | "external" | "public";
export type Environment = "local" | "development" | "dev" | "production";
export type SystemKeyFormat = "legacy" | "secret";

export type AuthContext =
  | { type: "system"; keyFormat?: SystemKeyFormat }
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
  rate_limit?: RateLimitConfig | RateLimitConfig[];
  idempotency?: IdempotencyConfig;
  /**
   * ISO date string (e.g. "2026-12-01") — if set, every response from this EF
   * will carry `Deprecation` and `Sunset` headers (RFC 8594) so clients can
   * detect the upcoming EOL without reading documentation.
   */
  deprecated?: string;
  description?: string;
}

export type RateLimitScope = "user" | "ip" | "auth_or_ip";

export interface RateLimitConfig {
  scope: RateLimitScope;
  /** Stable policy name. Final DB key is namespaced by function + caller. */
  bucket: string;
  /** Maximum burst tokens. */
  capacity: number;
  /** Tokens refilled per second. Token bucket semantics. */
  refill_per_second: number;
  /** Per-request cost. Defaults to 1. */
  cost?: number;
}

export interface IdempotencyConfig {
  /** Header name. Defaults to Idempotency-Key. */
  header?: string;
  /** Missing key returns 400 when true. */
  required?: boolean;
  /** Stable operation scope, for example "apply-event". */
  scope: string;
  /** Completed response cache TTL. Defaults to 24h. */
  ttl_seconds?: number;
  /** In-progress lock TTL. Defaults to 60s. */
  in_progress_ttl_seconds?: number;
  /** Cache 4xx responses as completed. Defaults to true. 5xx is never cached. */
  cache_errors?: boolean;
}

export type JsonBodyValidator = (
  body: Record<string, unknown>,
) => void | Response | Promise<void | Response>;

export interface RequestSchema {
  /** Allowed HTTP methods. OPTIONS is always handled before schema validation. */
  methods?: string[];
  /** JSON object body validator. Uses req.clone(), so handlers can still read req. */
  jsonBody?: JsonBodyValidator;
}

export interface MinglitEFOptions {
  /**
   * fnName override. 기본값: Deno.mainModule 에서 자동 감지.
   * 테스트 환경에서 mainModule 이 EF 디렉토리를 가리키지 않을 때 명시적으로 설정.
   */
  fnName?: string;
  /**
   * Opt-in request schema enforcement before auth/rate-limit/idempotency side
   * effects. Use this when an EF has a stable JSON request contract.
   */
  schema?: RequestSchema;
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
export function addDeprecationHeaders(
  res: Response,
  deprecated: string,
): Response {
  const date = new Date(deprecated);
  if (Number.isNaN(date.getTime())) return res;
  const httpDate = date.toUTCString();
  const headers = new Headers(res.headers);
  // RFC 8594 §2 — Deprecation header: date-tagged form "@<HTTP-date>"
  headers.set("Deprecation", `@${httpDate}`);
  // RFC 8594 §3 — Sunset header: the point at which the resource is removed
  headers.set("Sunset", httpDate);
  return new Response(res.body, {
    status: res.status,
    statusText: res.statusText,
    headers,
  });
}

function jsonResponse(
  body: unknown,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

async function sha256Hex(input: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function enforceRequestSchema(
  req: Request,
  schema?: RequestSchema,
): Promise<Response | undefined> {
  if (!schema) return undefined;

  if (schema.methods && !schema.methods.includes(req.method)) {
    return errorResponse("Method not allowed", 405);
  }

  if (schema.jsonBody) {
    const body = await parseJsonBody(req.clone());
    if (body instanceof Response) return body;
    const validation = await schema.jsonBody(body);
    if (validation instanceof Response) return validation;
  }

  return undefined;
}

/**
 * Trusted client-IP extraction for public/IP rate limits and IP allowlists.
 *
 * Assumption: these headers are set by Supabase/Cloudflare ingress. If callers
 * can inject them directly in a non-proxied local setup, IP buckets still fail
 * closed to a shared "unknown" key rather than bypassing the limit.
 */
export function getTrustedClientIp(req: Request): string | null {
  const realIp = req.headers.get("x-real-ip");
  if (realIp) return realIp.trim();

  const cfIp = req.headers.get("cf-connecting-ip");
  if (cfIp) return cfIp.trim();

  const xff = req.headers.get("x-forwarded-for");
  if (!xff) return null;
  return xff.split(",").map((s) => s.trim()).filter(Boolean).pop() ?? null;
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
      const clientIp = getTrustedClientIp(req);
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
      const sigHex = signature.startsWith("sha256=")
        ? signature.slice(7)
        : signature;
      // Reject odd-length or non-hex chars before decoding. parseInt("aZ",16) silently
      // stops at "Z" returning 10, so a regex guard is required to reject malformed input.
      if (sigHex.length % 2 !== 0 || !/^[0-9a-fA-F]+$/.test(sigHex)) {
        return { ok: false };
      }
      const sigBytes = new Uint8Array(sigHex.length / 2);
      for (let i = 0; i < sigHex.length; i += 2) {
        sigBytes[i / 2] = parseInt(sigHex.slice(i, i + 2), 16);
      }

      // crypto.subtle.verify performs constant-time HMAC comparison internally.
      const valid = await crypto.subtle.verify(
        "HMAC",
        key,
        sigBytes,
        new TextEncoder().encode(body),
      );
      if (valid) {
        return { ok: true, reason: `hmac:${external.header}` };
      }
      return { ok: false };
    }

    case "custom": {
      // Resolve path relative to this EF's directory (escape hatch for bespoke auth).
      const moduleUrl = new URL(
        external.module,
        new URL(`../${fnName}/`, import.meta.url),
      );
      const mod = await import(moduleUrl.href) as CustomAuthChecker;
      return await mod.check(req);
    }
  }
}

/**
 * Checks system caller credentials.
 *
 * Legacy service_role JWT stays on `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`.
 * New Supabase secret keys (`SUPABASE_SECRET_KEYS['default']`, `sb_secret_...`) are
 * not JWTs and must use `apikey`.
 * Exported for unit testing; not part of the stable public API.
 */
export function checkSystemAuth(
  req: Request,
): { ok: true; keyFormat: SystemKeyFormat } | { ok: false } {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const serviceKey = getLegacyServiceRoleJwt();

    if (serviceKey && token === serviceKey) {
      return { ok: true, keyFormat: "legacy" };
    }
  }

  const apiKey = req.headers.get("apikey") ?? "";
  if (apiKey && getSupabaseSecretApiKeys().includes(apiKey)) {
    return { ok: true, keyFormat: "secret" };
  }

  return { ok: false };
}

// Exported for unit testing; not part of the stable public API.
export async function verifyAuth(
  req: Request,
  policy: EFPolicy,
  fnName: string,
): Promise<AuthContext | Response> {
  const allow = (c: Caller) => policy.callers.includes(c);
  const authHeader = req.headers.get("Authorization") ?? "";

  // system auth is cheap and independent of JWT verification. Check it before
  // user auth so service-to-service callers can use only `apikey`.
  if (allow("system")) {
    const system = checkSystemAuth(req);
    if (system.ok) {
      return { type: "system", keyFormat: system.keyFormat };
    }
  }

  // Bearer 형식 토큰이 있으면 user JWT 검증 (expensive)
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.slice(7);

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
      throw new Error(
        `[minglitEdgeFunction] policy.callers includes 'external' but external_auth missing`,
      );
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

function firstRpcRow<T>(data: unknown): T | undefined {
  if (Array.isArray(data)) return data[0] as T | undefined;
  if (data && typeof data === "object") return data as T;
  return undefined;
}

function normalizeRateLimits(
  rateLimit?: RateLimitConfig | RateLimitConfig[],
): RateLimitConfig[] {
  if (!rateLimit) return [];
  return Array.isArray(rateLimit) ? rateLimit : [rateLimit];
}

function rateLimitRequesterKey(
  req: Request,
  auth: AuthContext,
  scope: RateLimitScope,
): string | Response {
  if (scope === "user") {
    if (auth.type !== "user") {
      return errorResponse("Rate limit requires user auth", 401);
    }
    return `user:${auth.userId}`;
  }

  if (scope === "auth_or_ip" && auth.type === "user") {
    return `user:${auth.userId}`;
  }

  const ip = getTrustedClientIp(req) ?? "unknown";
  return `ip:${ip}`;
}

async function enforceRateLimits(
  req: Request,
  ctx: EFContext,
  policy: EFPolicy,
): Promise<Response | undefined> {
  for (const limit of normalizeRateLimits(policy.rate_limit)) {
    const requester = rateLimitRequesterKey(req, ctx.auth, limit.scope);
    if (requester instanceof Response) return requester;

    const key = `ef:${ctx.fnName}:${limit.bucket}:${limit.scope}:${requester}`;
    const { data, error } = await ctx.supabase.rpc(
      "consume_edge_rate_limit",
      {
        p_key: key,
        p_capacity: limit.capacity,
        p_refill_per_second: limit.refill_per_second,
        p_cost: limit.cost ?? 1,
      },
    );

    if (error) {
      axiomLog({
        function: ctx.fnName,
        level: "error",
        message: "rate limit check failed",
        metadata: { requestId: ctx.requestId, detail: error.message },
      });
      return errorResponse("Rate limit unavailable", 500);
    }

    const row = firstRpcRow<{
      allowed: boolean;
      remaining: number | string;
      retry_after_seconds: number | string;
    }>(data);
    if (!row) return errorResponse("Rate limit unavailable", 500);

    if (!row.allowed) {
      const retryAfter = Math.max(
        1,
        Math.ceil(Number(row.retry_after_seconds) || 1),
      );
      const res = errorResponse(
        "Rate limit exceeded",
        429,
        { retry_after_seconds: retryAfter },
      );
      res.headers.set("Retry-After", String(retryAfter));
      return res;
    }
  }

  return undefined;
}

export interface ActiveIdempotency {
  readonly scope: string;
  readonly requesterKey: string;
  readonly key: string;
  readonly requestHash: string;
  readonly config: IdempotencyConfig;
}

function idempotencyRequesterKey(req: Request, auth: AuthContext): string {
  switch (auth.type) {
    case "user":
      return `user:${auth.userId}`;
    case "system":
      return `system:${auth.keyFormat ?? "unknown"}`;
    case "external":
      return `external:${auth.reason}`;
    case "public":
      return `ip:${getTrustedClientIp(req) ?? "unknown"}`;
  }
}

function readIdempotencyKey(
  req: Request,
  config: IdempotencyConfig,
): string | Response | undefined {
  const header = config.header ?? "Idempotency-Key";
  const raw = req.headers.get(header);
  const key = raw?.trim();

  if (!key) {
    return config.required
      ? errorResponse(`Missing ${header}`, 400)
      : undefined;
  }

  if (key.length > 255 || /[\u0000-\u001f\u007f]/.test(key)) {
    return errorResponse(`Invalid ${header}`, 400);
  }

  return key;
}

async function requestHash(req: Request): Promise<string> {
  const url = new URL(req.url);
  const body = await req.clone().text();
  return await sha256Hex(
    `${req.method}\n${url.pathname}${url.search}\n${body}`,
  );
}

async function beginIdempotency(
  req: Request,
  ctx: EFContext,
  config?: IdempotencyConfig,
): Promise<{ active?: ActiveIdempotency; response?: Response }> {
  if (!config) return {};

  const key = readIdempotencyKey(req, config);
  if (key instanceof Response) return { response: key };
  if (!key) return {};

  const requesterKey = idempotencyRequesterKey(req, ctx.auth);
  const hash = await requestHash(req);
  const { data, error } = await ctx.supabase.rpc(
    "begin_edge_idempotency",
    {
      p_scope: config.scope,
      p_requester_key: requesterKey,
      p_idempotency_key: key,
      p_request_hash: hash,
      p_ttl_seconds: config.ttl_seconds ?? 86_400,
      p_in_progress_ttl_seconds: config.in_progress_ttl_seconds ?? 60,
    },
  );

  if (error) {
    axiomLog({
      function: ctx.fnName,
      level: "error",
      message: "idempotency begin failed",
      metadata: { requestId: ctx.requestId, detail: error.message },
    });
    return { response: errorResponse("Idempotency check failed", 500) };
  }

  const row = firstRpcRow<{
    decision: "started" | "replay" | "in_progress" | "conflict";
    response_status: number | null;
    response_body: unknown;
    retry_after_seconds: number | string | null;
  }>(data);

  if (!row) return { response: errorResponse("Idempotency check failed", 500) };

  if (row.decision === "started") {
    return {
      active: {
        scope: config.scope,
        requesterKey,
        key,
        requestHash: hash,
        config,
      },
    };
  }

  if (row.decision === "replay") {
    const res = jsonResponse(
      row.response_body ?? {},
      row.response_status ?? 200,
    );
    res.headers.set("Idempotency-Replayed", "true");
    return { response: res };
  }

  const retryAfter = Math.max(
    1,
    Math.ceil(Number(row.retry_after_seconds) || 1),
  );
  const message = row.decision === "conflict"
    ? "Idempotency key reused with a different request"
    : "Idempotency key is already in progress";
  const res = errorResponse(message, 409, { retry_after_seconds: retryAfter });
  res.headers.set("Retry-After", String(retryAfter));
  return { response: res };
}

async function failIdempotency(
  ctx: EFContext,
  active: ActiveIdempotency,
  ttlSeconds?: number,
): Promise<void> {
  const params: Record<string, unknown> = {
    p_scope: active.scope,
    p_requester_key: active.requesterKey,
    p_idempotency_key: active.key,
    p_request_hash: active.requestHash,
  };
  if (ttlSeconds !== undefined) {
    params.p_ttl_seconds = ttlSeconds;
  }

  const { error } = await ctx.supabase.rpc(
    "fail_edge_idempotency",
    params,
  );
  if (error) {
    axiomLog({
      function: ctx.fnName,
      level: "warn",
      message: "idempotency fail mark failed",
      metadata: { requestId: ctx.requestId, detail: error.message },
    });
  }
}

async function completeIdempotency(
  ctx: EFContext,
  active: ActiveIdempotency,
  res: Response,
): Promise<void> {
  const cacheErrors = active.config.cache_errors ?? true;
  if (res.status >= 500 || (!cacheErrors && res.status >= 400)) {
    await failIdempotency(ctx, active);
    return;
  }

  const contentType = res.headers.get("Content-Type") ?? "";
  if (!contentType.toLowerCase().includes("application/json")) {
    await failIdempotency(ctx, active);
    return;
  }

  let body: unknown;
  try {
    body = await res.clone().json();
  } catch {
    await failIdempotency(ctx, active);
    return;
  }

  const { error } = await ctx.supabase.rpc(
    "complete_edge_idempotency",
    {
      p_scope: active.scope,
      p_requester_key: active.requesterKey,
      p_idempotency_key: active.key,
      p_request_hash: active.requestHash,
      p_response_status: res.status,
      p_response_body: body,
      p_ttl_seconds: active.config.ttl_seconds ?? 86_400,
    },
  );
  if (error) {
    axiomLog({
      function: ctx.fnName,
      level: "warn",
      message: "idempotency complete failed",
      metadata: { requestId: ctx.requestId, detail: error.message },
    });
  }
}

// --------------------------------------------------------------------------
// Public API
// --------------------------------------------------------------------------

export function minglitEdgeFunction(
  handler: EFHandler,
  opts: MinglitEFOptions = {},
): void {
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
    axiomLog({
      function: fnName,
      level: "info",
      message: "invoked",
      metadata: { method: req.method, requestId },
    });

    let requestCtx: EFContext | undefined;
    let activeIdempotency: ActiveIdempotency | undefined;
    try {
      // CORS preflight
      if (req.method === "OPTIONS") return corsResponse();

      // Env 가드
      if (!policy.envs.includes(env)) {
        return errorResponse(`Function disabled in ${env}`, 403);
      }

      // Schema validation runs before expensive side effects. It uses req.clone()
      // so existing handlers can continue to parse the original request body.
      const schemaError = await enforceRequestSchema(req, opts.schema);
      if (schemaError) return schemaError;

      // Auth 검증
      const auth = await verifyAuth(req, policy, fnName);
      if (auth instanceof Response) return auth;
      if (auth.type === "system") {
        axiomLog({
          function: fnName,
          level: "info",
          message: "system auth accepted",
          metadata: { requestId, keyFormat: auth.keyFormat ?? "unknown" },
        });
      }

      // Context + handler 호출
      const ctx = makeContext({ auth, fnName, env, requestId });
      requestCtx = ctx;
      const idempotency = await beginIdempotency(
        req,
        ctx,
        policy.idempotency,
      );
      if (idempotency.response) return idempotency.response;
      activeIdempotency = idempotency.active;

      const rateLimitError = await enforceRateLimits(req, ctx, policy);
      if (rateLimitError) {
        if (activeIdempotency) await failIdempotency(ctx, activeIdempotency, 0);
        return rateLimitError;
      }

      let res = await handler(req, ctx);
      if (policy.deprecated) {
        res = addDeprecationHeaders(res, policy.deprecated);
      }
      if (activeIdempotency) {
        await completeIdempotency(ctx, activeIdempotency, res);
      }
      axiomLog({
        function: fnName,
        level: "info",
        message: "completed",
        metadata: { status: res.status, requestId },
      });
      return res;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      axiomLog({
        function: fnName,
        level: "error",
        message: msg,
        metadata: { requestId },
      });
      captureException(e instanceof Error ? e : new Error(msg));
      if (activeIdempotency && requestCtx) {
        await failIdempotency(requestCtx, activeIdempotency);
      }
      return errorResponse("Internal error", 500);
    } finally {
      await axiomFlush();
    }
  });
}
