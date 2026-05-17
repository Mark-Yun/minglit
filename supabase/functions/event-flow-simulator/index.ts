// index.ts — event-flow-simulator EF 진입점 (v2 Stochastic Cascade)
//
// 옛 phase/tick 분기 제거. 단일 cascade 엔진 호출.
// 상세: ./architecture.md (Stochastic Cascade 모델)

import { createServiceClient } from "../_shared/supabase_client.ts";
import { corsResponse, errorResponse, successResponse } from "../_shared/response_utils.ts";
import { parseJsonBody } from "../_shared/request_utils.ts";
import { flush, log } from "../_shared/axiom_logger.ts";
import { minglitEdgeFunction, type EFContext } from "../_shared/edge_function.ts";

import { runCascade } from "./core/cascade.ts";
import { createPRNG } from "./core/types.ts";
import { EFTransport } from "./core/transport.ts";
import { buildSnapshot } from "./core/snapshot.ts";
import { reportFailure, summarizeTrace } from "./core/reporter.ts";
import {
  getPartnerEmail,
  getSimPartnerToken,
  getSimUserToken,
} from "./core/auth.ts";
import type { Actor, ActorId } from "./core/types.ts";

import { defaultRates } from "./params/default.ts";
import { checkAll } from "./invariant/_registry.ts";

// side-effect imports: 모든 액션 등록.
// invariant 는 현재 인프라만 — 실 invariant set 은 별도 RFC (architecture.md Part 2.B)
import "./action/index.ts";

const FN = "event-flow-simulator";

export const handler = async (req: Request, _ctx: EFContext): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const simPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (!supabaseUrl || !anonKey || !simPassword) {
    return errorResponse("Missing required env vars (SUPABASE_URL / ANON_KEY / SIM_USER_PASSWORD)", 500);
  }

  const supabase = createServiceClient();

  // optional body params
  let body: { ticks?: number; seed?: number; usersPerTick?: number } = {};
  try {
    if (req.headers.get("content-type")?.includes("application/json")) {
      const parsed = await parseJsonBody(req);
      if (!(parsed instanceof Response)) body = parsed as typeof body;
    }
  } catch {
    // ignore
  }

  const runId = crypto.randomUUID();
  const ticks = body.ticks ?? 1;
  const seed = body.seed ?? Date.now();
  const usersPerTick = body.usersPerTick ?? 10;

  log({
    function: FN,
    level: "info",
    message: "invoked",
    metadata: { runId, ticks, seed, usersPerTick },
  });

  try {
    // 1. 초기 snapshot 채움
    const initialSnapshot = await buildSnapshot(supabase);

    // 2. actor 발굴 + 토큰 prefetch
    //    partner: 모든 [E2E] partner. user: seed user_ prefix 중 N명.
    const partnerIds = [...new Set(initialSnapshot.parties.map((p) => p.partner_id))];

    const { data: userRows } = await supabase
      .from("user_profiles")
      .select("id, username")
      .like("username", "user\\_%")
      .not("username", "like", "partner\\_%")
      .limit(usersPerTick);
    const users = (userRows ?? []) as Array<{ id: string; username: string }>;

    const tokenByActor = new Map<ActorId, string>();
    const actors: Actor[] = [];

    for (const partnerId of partnerIds) {
      try {
        const email = await getPartnerEmail(supabase, partnerId);
        if (!email) continue;
        const token = await getSimPartnerToken(supabaseUrl, anonKey, email, simPassword);
        tokenByActor.set(partnerId, token);
        actors.push({ id: partnerId, role: "partner" });
      } catch (e) {
        log({
          function: FN, level: "warn", message: "partner_auth_skip",
          metadata: { partnerId, error: String(e) },
        });
      }
    }

    for (const user of users) {
      try {
        const { data: authData } = await supabase.auth.admin.getUserById(user.id);
        const email = authData?.user?.email;
        if (!email) continue;
        const token = await getSimUserToken(supabaseUrl, anonKey, email, simPassword);
        tokenByActor.set(user.id, token);
        actors.push({ id: user.id, role: "user" });
      } catch (e) {
        log({
          function: FN, level: "warn", message: "user_auth_skip",
          metadata: { userId: user.id, error: String(e) },
        });
      }
    }

    // 3. cascade 실행
    const transport = new EFTransport({ supabase, supabaseUrl, tokenByActor });
    const cascade = await runCascade({
      actors,
      initialSnapshot,
      rates: defaultRates,
      transport,
      rng: createPRNG(seed),
      ticks,
      refreshSnapshot: () => buildSnapshot(supabase),
    });

    // 4. invariant 검증
    const violations = await checkAll(supabase);
    const summary = summarizeTrace(cascade.trace);
    const githubIssueUrl = await reportFailure({
      runId,
      trace: cascade.trace,
      violations,
    });

    log({
      function: FN,
      level: summary.failed > 0 || violations.length > 0 ? "error" : "info",
      message: "completed",
      metadata: {
        runId,
        actorsCount: actors.length,
        traceTotal: summary.total,
        traceOk: summary.ok,
        traceFailed: summary.failed,
        violations: violations.length,
        githubIssueUrl,
      },
    });

    const ok = summary.failed === 0 && violations.length === 0;
    return successResponse(
      {
        success: ok,
        run_id: runId,
        actors: actors.length,
        trace_summary: summary,
        violations,
        github_issue_url: githubIssueUrl,
      },
      ok ? 200 : 500,
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    log({
      function: FN,
      level: "error",
      message: "unhandled exception",
      metadata: { runId, error: message },
    });
    return errorResponse(`Unhandled exception: ${message}`, 500);
  } finally {
    try {
      await flush();
    } catch (e) {
      console.error("[event-flow-simulator] flush failed", e);
    }
  }
};

minglitEdgeFunction(handler);
