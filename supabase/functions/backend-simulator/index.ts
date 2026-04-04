// backend-simulator/index.ts — Main Edge Function handler for backend simulation

import { createServiceClient } from "../_shared/supabase_client.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
} from "../_shared/response_utils.ts";
import { log, flush, debugStatus } from "../_shared/axiom_logger.ts";
import {
  SimLogCollector,
  simCreateGitHubIssue,
  simUploadLog,
} from "./sim_reporter.ts";
import { simCreateParties, simCreateDisplayEvents, simDiscoverAndApply } from "./sim_create.ts";
import { simApproveVerifications } from "./sim_approve.ts";
import { simRefundRequests } from "./sim_refund.ts";
import { simCheckin, simCompleteEvents, simMatch } from "./sim_event.ts";
import { simTransitionToReady, simVerifySettlement } from "./sim_settle.ts";
import type {
  SimAssertionResult,
  SimConfig,
  SimLogEntry,
  SimSummary,
} from "./sim_types.ts";

// ─────────────────────────────────────────────────────────
// Dev guard
// ─────────────────────────────────────────────────────────

function isProduction(): boolean {
  const env = Deno.env.get("ENVIRONMENT");
  return env !== "local" && env !== "development";
}

// ─────────────────────────────────────────────────────────
// Defaults
// ─────────────────────────────────────────────────────────

const DEFAULT_CONFIG: SimConfig = {
  error_rate: 0.2,
  refund_rate: 0.2,
  party_count: 5,
  events_per_party: 4,
  apps_per_event: 6,
  checkin_rate: 0.7,
  no_show_rate: 0.3,
};

// ─────────────────────────────────────────────────────────
// Handler
// ─────────────────────────────────────────────────────────

const FN = "backend-simulator";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return corsResponse();
  if (isProduction()) return errorResponse("Dev only", 403);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return errorResponse("Missing required environment variables", 500);
  }
  const supabase = createServiceClient();

  // Parse request body
  let body: {
    phase?: string;
    force_fail?: boolean;
    config?: Partial<SimConfig>;
  } = {};
  try {
    if (req.headers.get("content-type")?.includes("application/json")) {
      body = await req.json();
    }
  } catch {
    // ignore parse errors — use defaults
  }

  const config: SimConfig = { ...DEFAULT_CONFIG, ...(body.config ?? {}) };
  const forceFail = body.force_fail ?? false;
  const phase = body.phase;

  const runId = crypto.randomUUID();
  log({ function: FN, level: "info", message: "invoked", metadata: { runId, phase: body.phase ?? "full", forceFail } });

  try {

  const collector = new SimLogCollector();

  // Log adapter: sim modules expect (entry: Omit<SimLogEntry, "timestamp">) => void
  const logFn = (entry: Omit<SimLogEntry, "timestamp">) => {
    collector.log(
      entry.level,
      entry.phase,
      entry.step,
      entry.message,
      entry.data,
    );
  };

  // ─────────────────────────────────────────────────────────
  // Phase routing
  // ─────────────────────────────────────────────────────────

  // Phase: "create" → Phase 1-2 only
  if (phase === "create") {
    const createResult = await simCreateParties(supabase, config, logFn);
    // Fix #964: 피드 전시용 이벤트 생성 — 일반 유저 피드에 표시할 display 이벤트를 E2E와 분리해 생성
    const displayResult = await simCreateDisplayEvents(supabase, logFn);
    const applyResult = await simDiscoverAndApply(
      supabase,
      config,
      logFn,
      createResult.eventIds,
      supabaseUrl,
      anonKey,
    );
    return successResponse({
      success: true,
      run_id: runId,
      party_ids: createResult.partyIds,
      event_ids: createResult.eventIds,
      display_party_ids: displayResult.displayPartyIds,
      display_event_ids: displayResult.displayEventIds,
      application_ids: applyResult.applicationIds,
      paid_application_ids: applyResult.paidApplicationIds,
      pending_review_application_ids: applyResult.pendingReviewApplicationIds,
    });
  }

  // Phase: "approve" → Phase 3 only
  if (phase === "approve") {
    // Fetch current pendingReview applications from DB
    const { data: pendingApps, error: fetchErr } = await supabase
      .from("event_applications")
      .select("id")
      .eq("status", "pending_review")
      .limit(50);

    if (fetchErr) {
      return errorResponse(`Failed to fetch pending applications: ${fetchErr.message}`, 500);
    }

    const pendingIds = ((pendingApps ?? []) as Array<{ id: string }>).map(
      (a) => a.id,
    );
    const approveResult = await simApproveVerifications(
      supabase,
      pendingIds,
      logFn,
    );
    return successResponse({
      success: true,
      run_id: runId,
      approved_application_ids: approveResult.approvedApplicationIds,
      rejected_application_ids: approveResult.rejectedApplicationIds,
      assertions: approveResult.assertions,
    });
  }

  // Phase: "refund" → Phase 4 only
  if (phase === "refund") {
    const { data: paidApps, error: fetchErr } = await supabase
      .from("event_applications")
      .select("id")
      .eq("status", "paid")
      .limit(50);

    if (fetchErr) {
      return errorResponse(`Failed to fetch paid applications: ${fetchErr.message}`, 500);
    }

    const paidIds = ((paidApps ?? []) as Array<{ id: string }>).map(
      (a) => a.id,
    );
    const refundResult = await simRefundRequests(
      supabase,
      paidIds,
      logFn,
      config.refund_rate,
      supabaseUrl,
      anonKey,
    );
    return successResponse({
      success: true,
      run_id: runId,
      refunded_application_ids: refundResult.refundedApplicationIds,
      assertions: refundResult.assertions,
    });
  }

  // Phase: "run" → Phase 5 only (checkin + match + complete)
  if (phase === "run") {
    // Fix #964: E2E 전용 필터 — run phase는 [E2E] 파티 이벤트만 처리해 비E2E 데이터 오염 방지
    const { data: scheduledEvents, error: fetchErr } = await supabase
      .from("events")
      .select("id, parties!inner(title)")
      .eq("status", "scheduled")
      .filter("parties.title", "like", "[E2E]%")
      .limit(50);

    if (fetchErr) {
      return errorResponse(`Failed to fetch events: ${fetchErr.message}`, 500);
    }

    const eventIds = ((scheduledEvents ?? []) as Array<{ id: string }>).map(
      (e) => e.id,
    );
    const checkinResult = await simCheckin(
      supabase,
      eventIds,
      logFn,
      config.checkin_rate,
      supabaseUrl,
      anonKey,
    );
    const matchResult = await simMatch(supabase, eventIds, logFn, supabaseUrl, serviceRoleKey);
    const completeResult = await simCompleteEvents(supabase, eventIds, logFn);

    const allAssertions: SimAssertionResult[] = [
      ...checkinResult.assertions,
      ...matchResult.assertions,
      ...completeResult.assertions,
    ];

    return successResponse({
      success: true,
      run_id: runId,
      checked_in_participant_ids: checkinResult.checkedInParticipantIds,
      no_show_participant_ids: checkinResult.noShowParticipantIds,
      match_pairs: matchResult.matchPairs,
      completed_event_ids: completeResult.completedEventIds,
      assertions: allAssertions,
    });
  }

  // Phase: "settle" → Phase 6 only
  if (phase === "settle") {
    // Fix #964: E2E 전용 필터 — settle phase는 [E2E] 파티 이벤트만 처리해 비E2E 데이터 오염 방지
    const { data: completedEvents, error: fetchErr } = await supabase
      .from("events")
      .select("id, parties!inner(title)")
      .eq("status", "completed")
      .filter("parties.title", "like", "[E2E]%")
      .limit(50);

    if (fetchErr) {
      return errorResponse(`Failed to fetch completed events: ${fetchErr.message}`, 500);
    }

    const completedEventIds = (
      (completedEvents ?? []) as Array<{ id: string }>
    ).map((e) => e.id);
    const settleResult = await simVerifySettlement(
      supabase,
      completedEventIds,
      logFn,
    );
    const readyResult = await simTransitionToReady(
      supabase,
      settleResult.settlementIds,
      logFn,
    );

    const allAssertions: SimAssertionResult[] = [
      ...settleResult.assertions,
      ...readyResult.assertions,
    ];

    return successResponse({
      success: true,
      run_id: runId,
      settlement_ids: settleResult.settlementIds,
      ready_ids: readyResult.readyIds,
      assertions: allAssertions,
    });
  }

  // Phase: "verify" → read-only assertion check against current DB state
  if (phase === "verify") {
    // Fix #964: E2E 전용 필터 — verify phase는 [E2E] 파티 이벤트만 검증해 비E2E 데이터 오염 방지
    // Collect assertions from settlement state only (non-destructive)
    const { data: completedEvents, error: fetchErr } = await supabase
      .from("events")
      .select("id, parties!inner(title)")
      .eq("status", "completed")
      .filter("parties.title", "like", "[E2E]%")
      .limit(50);

    if (fetchErr) {
      return errorResponse(`Failed to fetch completed events: ${fetchErr.message}`, 500);
    }

    const completedEventIds = (
      (completedEvents ?? []) as Array<{ id: string }>
    ).map((e) => e.id);

    const settleResult = await simVerifySettlement(
      supabase,
      completedEventIds,
      logFn,
    );

    const summary: SimSummary = {
      total_checks: settleResult.assertions.length,
      passed: settleResult.assertions.filter((a) => a.passed).length,
      failed: settleResult.assertions.filter((a) => !a.passed).length,
      assertion_results: settleResult.assertions,
    };

    // Create GitHub issue on assertion failure
    let githubIssueUrl: string | null = null;
    if (summary.failed > 0) {
      const logText = collector.formatAsText();
      const logUrl = await simUploadLog(supabase, runId, logText);
      githubIssueUrl = await simCreateGitHubIssue(
        summary,
        logUrl,
        runId,
        logText,
      );
    }

    return successResponse({
      success: summary.failed === 0,
      run_id: runId,
      summary,
      github_issue_url: githubIssueUrl,
      _axiom_debug: debugStatus(),
    });
  }

  // ─────────────────────────────────────────────────────────
  // Full 6-phase run (no phase param)
  // ─────────────────────────────────────────────────────────

  // Phase 1-2: Create parties + display events + discover & apply
  const createResult = await simCreateParties(supabase, config, logFn);
  // Fix #964: 피드 전시용 이벤트 생성 — 일반 유저 피드에 표시할 display 이벤트를 E2E와 분리해 생성
  await simCreateDisplayEvents(supabase, logFn);
  const applyResult = await simDiscoverAndApply(
    supabase,
    config,
    logFn,
    createResult.eventIds,
    supabaseUrl,
    anonKey,
  );

  // Phase 3: Approve verifications (80% approve, 20% reject)
  const approveResult = await simApproveVerifications(
    supabase,
    applyResult.pendingReviewApplicationIds,
    logFn,
  );

  // Phase 4: Refund requests (refund_rate % of paid)
  const refundResult = await simRefundRequests(
    supabase,
    applyResult.paidApplicationIds,
    logFn,
    config.refund_rate,
    supabaseUrl,
    anonKey,
  );

  // Phase 5: Check-in + Match + Complete
  const checkinResult = await simCheckin(
    supabase,
    createResult.eventIds,
    logFn,
    config.checkin_rate,
    supabaseUrl,
    anonKey,
  );
  const matchResult = await simMatch(supabase, createResult.eventIds, logFn, supabaseUrl, serviceRoleKey);
  const completeResult = await simCompleteEvents(
    supabase,
    createResult.eventIds,
    logFn,
  );

  // Phase 6: Verify settlement + transition to ready
  const settleResult = await simVerifySettlement(
    supabase,
    completeResult.completedEventIds,
    logFn,
  );
  const readyResult = await simTransitionToReady(
    supabase,
    settleResult.settlementIds,
    logFn,
  );

  // Collect ALL assertions
  const allAssertions: SimAssertionResult[] = [
    ...approveResult.assertions,
    ...refundResult.assertions,
    ...checkinResult.assertions,
    ...matchResult.assertions,
    ...completeResult.assertions,
    ...settleResult.assertions,
    ...readyResult.assertions,
  ];

  // force_fail: add a deliberate failing assertion for reporter testing
  if (forceFail) {
    allAssertions.push({
      check_name: "force_fail_test",
      passed: false,
      expected: "always_fail",
      actual: "force_fail_triggered",
      details: "Deliberate failure for testing reporter",
    });
  }

  // Build summary
  const summary: SimSummary = {
    total_checks: allAssertions.length,
    passed: allAssertions.filter((a) => a.passed).length,
    failed: allAssertions.filter((a) => !a.passed).length,
    assertion_results: allAssertions,
  };

  // Upload log to Storage
  const logText = collector.formatAsText();
  const logUrl = await simUploadLog(supabase, runId, logText);

  // Create GitHub Issue if there are failures
  let githubIssueUrl: string | null = null;
  if (summary.failed > 0) {
    githubIssueUrl = await simCreateGitHubIssue(
      summary,
      logUrl,
      runId,
      logText,
    );
  }

  log({
    function: FN,
    level: summary.failed > 0 ? "error" : "info",
    message: "completed",
    metadata: { runId, passed: summary.passed, failed: summary.failed, total: summary.total_checks, logUrl, githubIssueUrl },
  });

  return successResponse({
    success: summary.failed === 0,
    run_id: runId,
    summary,
    log_url: logUrl,
    github_issue_url: githubIssueUrl,
  });

  } finally {
    await flush();
  }
});
