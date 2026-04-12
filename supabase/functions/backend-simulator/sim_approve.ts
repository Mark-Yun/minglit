// sim_approve.ts — Phase 3: Partner Approval + Error Scenarios

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import {
  simAssertVerificationApproved,
  simAssertApplicationApproved,
  simAssertApplicationRejected,
} from "./sim_assertions.ts";
import { getSimUserToken, getSimPartnerToken, getPartnerEmail, callEdgeFunction } from "./sim_auth.ts";

export interface SimApproveResult {
  approvedApplicationIds: string[];
  rejectedApplicationIds: string[];
  assertions: SimAssertionResult[];
}

/**
 * Processes pendingReview applications:
 * - approveRate (default 0.8) fraction → approve via verification flow
 * - remaining fraction → reject via verification flow
 *
 * For each application:
 *   1. Fetch app details (event_id, user_id)
 *   2. Fetch event's party for partner_id + required_verification_ids
 *   3. If verification needed: create submission → call partner-review-submission EF
 *   4. If no verification: call partner-approve-application EF (approve) or direct DB update (reject)
 */
export async function simApproveVerifications(
  supabase: SupabaseClient,
  pendingReviewApplicationIds: string[],
  log: (entry: Omit<SimLogEntry, "timestamp">) => void,
  approveRate: number = 0.8,
  supabaseUrl?: string,
  anonKey?: string,
  strict?: boolean,
): Promise<SimApproveResult> {
  const approvedApplicationIds: string[] = [];
  const rejectedApplicationIds: string[] = [];
  const assertions: SimAssertionResult[] = [];

  if (pendingReviewApplicationIds.length === 0) {
    log({ level: "info", phase: "approve", step: "skip", message: "No pendingReview applications to process" });
    return { approvedApplicationIds, rejectedApplicationIds, assertions };
  }

  const splitIndex = Math.floor(pendingReviewApplicationIds.length * approveRate);
  const toApprove = pendingReviewApplicationIds.slice(0, splitIndex);
  const toReject = pendingReviewApplicationIds.slice(splitIndex);

  log({
    level: "info",
    phase: "approve",
    step: "split",
    message: `Processing ${pendingReviewApplicationIds.length} apps: ${toApprove.length} approve, ${toReject.length} reject`,
  });

  // ── Approve flow ──────────────────────────────────────────
  for (const appId of toApprove) {
    try {
      const appInfo = await _fetchAppInfo(supabase, appId);
      if (!appInfo) {
        log({ level: "warn", phase: "approve", step: "fetch_app", message: `App ${appId} not found, skipping` });
        continue;
      }

      const { eventId, userId } = appInfo;
      const partnerInfo = await _fetchPartnerInfo(supabase, eventId);
      const partnerId = partnerInfo?.partnerId ?? null;
      const requiredVerifIds: string[] = partnerInfo?.requiredVerifIds ?? [];

      let verificationId: string | null = null;
      if (partnerId) {
        verificationId = await _resolveVerificationId(supabase, partnerId, requiredVerifIds);
      }

      if (verificationId && partnerId) {
        // Verification flow: call user-submit-verification EF → call partner-review-submission EF
        // Fix #1326: user-submit-verification EF로 전환 — direct DB insert 제거
        if (!supabaseUrl || !anonKey) {
          throw new Error(`App ${appId}: supabaseUrl/anonKey required for user-submit-verification EF`);
        }
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";

        const { data: profileData } = await supabase
          .from("user_profiles")
          .select("username")
          .eq("id", userId)
          .maybeSingle();
        const username = (profileData as { username?: string } | null)?.username;
        if (!username || username.startsWith("partner_")) {
          throw new Error(`App ${appId}: no valid user username (got: ${username ?? "null"}), cannot call user-submit-verification EF`);
        }
        const userEmail = `${username}@test.com`;
        const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
        const submitResult = await callEdgeFunction(supabaseUrl, "user-submit-verification", {
          action: "submit",
          partner_id: partnerId,
          verification_id: verificationId,
          application_id: appId,
        }, userToken);
        if (submitResult.status !== 200 && submitResult.status !== 201) {
          throw new Error(`user-submit-verification EF returned ${submitResult.status} for app ${appId}`);
        }

        // Retrieve the submission_id from EF response to pass to partner-review-submission
        // deno-lint-ignore no-explicit-any
        const submissionId: string = (submitResult.data as any)?.submission_id ?? (submitResult.data as any)?.id;
        if (!submissionId) {
          throw new Error(`user-submit-verification EF did not return submission_id for app ${appId}`);
        }
        log({ level: "info", phase: "approve", step: "ef_submit_verification", message: `Submitted verification ${submissionId} via EF for app ${appId}` });

        // Call partner-review-submission EF — no fallback. EF is the only path.
        // Fix #1280: remove direct DB fallback; EF failure is always an error.
        const partnerEmail = await getPartnerEmail(supabase, partnerId);
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (submission ${submissionId}, app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl, "partner-review-submission", {
          action: "review",
          submission_id: submissionId,
          result: "approved",
        }, partnerToken);
        if (efResult.status !== 200) {
          throw new Error(`partner-review-submission EF returned ${efResult.status} for submission ${submissionId} (app ${appId})`);
        }
        log({ level: "info", phase: "approve", step: "ef_approve", message: `Approved submission ${submissionId} via EF` });

        // Assert verification approved (trigger should have created partner_verified_users)
        const verifAssertion = await simAssertVerificationApproved(supabase, submissionId);
        assertions.push(verifAssertion);

        // Assert application approved (trigger should have updated status)
        const appAssertion = await simAssertApplicationApproved(supabase, appId);
        assertions.push(appAssertion);

        if (appAssertion.passed) {
          approvedApplicationIds.push(appId);
          log({ level: "info", phase: "approve", step: "approved", message: `App ${appId} approved via verification ${submissionId}` });
        } else {
          log({ level: "warn", phase: "approve", step: "approved", message: `App ${appId} approval assertion failed: ${appAssertion.details}` });
        }
      } else {
        // No verification needed: call partner-approve-application EF
        // Fix #1280: replace direct DB update with EF call for consistency.
        if (!supabaseUrl || !anonKey) {
          throw new Error(`App ${appId}: supabaseUrl/anonKey required for partner-approve-application EF`);
        }
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
        const partnerEmail = partnerId ? await getPartnerEmail(supabase, partnerId) : null;
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl, "partner-approve-application", {
          action: "approve",
          application_id: appId,
        }, partnerToken);
        if (efResult.status !== 200) {
          throw new Error(`partner-approve-application EF returned ${efResult.status} for app ${appId}`);
        }
        log({ level: "info", phase: "approve", step: "ef_direct_approve", message: `Approved app ${appId} via partner-approve-application EF` });

        const appAssertion = await simAssertApplicationApproved(supabase, appId);
        assertions.push(appAssertion);

        if (appAssertion.passed) {
          approvedApplicationIds.push(appId);
          log({ level: "info", phase: "approve", step: "approved", message: `App ${appId} directly approved (no verification required)` });
        } else {
          log({ level: "warn", phase: "approve", step: "approved", message: `App ${appId} direct approval assertion failed: ${appAssertion.details}` });
        }
      }
    } catch (e) {
      if (strict) throw e;
      log({ level: "error", phase: "approve", step: "approve_loop", message: `Unexpected error for app ${appId}: ${String(e)}` });
    }
  }

  // ── Reject flow ───────────────────────────────────────────
  for (const appId of toReject) {
    try {
      const appInfo = await _fetchAppInfo(supabase, appId);
      if (!appInfo) {
        log({ level: "warn", phase: "approve", step: "fetch_app", message: `App ${appId} not found, skipping` });
        continue;
      }

      const { eventId, userId } = appInfo;
      const partnerInfo = await _fetchPartnerInfo(supabase, eventId);
      const partnerId = partnerInfo?.partnerId ?? null;
      const requiredVerifIds: string[] = partnerInfo?.requiredVerifIds ?? [];

      let verificationId: string | null = null;
      if (partnerId) {
        verificationId = await _resolveVerificationId(supabase, partnerId, requiredVerifIds);
      }

      if (verificationId && partnerId) {
        // Verification flow: call user-submit-verification EF → call partner-review-submission EF
        // Fix #1326: user-submit-verification EF로 전환 — direct DB insert 제거
        if (!supabaseUrl || !anonKey) {
          throw new Error(`App ${appId}: supabaseUrl/anonKey required for user-submit-verification EF`);
        }
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";

        const { data: profileData } = await supabase
          .from("user_profiles")
          .select("username")
          .eq("id", userId)
          .maybeSingle();
        const username = (profileData as { username?: string } | null)?.username;
        if (!username || username.startsWith("partner_")) {
          throw new Error(`App ${appId}: no valid user username (got: ${username ?? "null"}), cannot call user-submit-verification EF`);
        }
        const userEmail = `${username}@test.com`;
        const userToken = await getSimUserToken(supabaseUrl, anonKey, userEmail, simUserPassword);
        const submitResult = await callEdgeFunction(supabaseUrl, "user-submit-verification", {
          action: "submit",
          partner_id: partnerId,
          verification_id: verificationId,
          application_id: appId,
        }, userToken);
        if (submitResult.status !== 200 && submitResult.status !== 201) {
          throw new Error(`user-submit-verification EF returned ${submitResult.status} for app ${appId}`);
        }

        // Retrieve the submission_id from EF response to pass to partner-review-submission
        // deno-lint-ignore no-explicit-any
        const submissionId: string = (submitResult.data as any)?.submission_id ?? (submitResult.data as any)?.id;
        if (!submissionId) {
          throw new Error(`user-submit-verification EF did not return submission_id for app ${appId}`);
        }
        log({ level: "info", phase: "approve", step: "ef_submit_verification", message: `Submitted verification ${submissionId} via EF for app ${appId}` });

        // Call partner-review-submission EF — no fallback. EF is the only path.
        // Fix #1280: remove direct DB fallback; EF failure is always an error.
        const partnerEmail = await getPartnerEmail(supabase, partnerId);
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (submission ${submissionId}, app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl, "partner-review-submission", {
          action: "review",
          submission_id: submissionId,
          result: "rejected",
        }, partnerToken);
        if (efResult.status !== 200) {
          throw new Error(`partner-review-submission EF returned ${efResult.status} for submission ${submissionId} (app ${appId})`);
        }
        log({ level: "info", phase: "approve", step: "ef_reject", message: `Rejected submission ${submissionId} via EF` });

        // Assert application rejected (trigger should have updated status)
        const appAssertion = await simAssertApplicationRejected(supabase, appId);
        assertions.push(appAssertion);

        if (appAssertion.passed) {
          rejectedApplicationIds.push(appId);
          log({ level: "info", phase: "approve", step: "rejected", message: `App ${appId} rejected via verification ${submissionId}` });
        } else {
          log({ level: "warn", phase: "approve", step: "rejected", message: `App ${appId} rejection assertion failed: ${appAssertion.details}` });
        }
      } else {
        // No verification needed: reject via partner-reject-application EF
        // Fix #1328: partner-reject-application EF 호출 — direct DB update 제거
        if (!supabaseUrl || !anonKey) {
          throw new Error(`App ${appId}: supabaseUrl/anonKey required for partner-reject-application EF`);
        }
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
        const partnerEmail = partnerId ? await getPartnerEmail(supabase, partnerId) : null;
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl, "partner-reject-application", {
          application_id: appId,
          reason: "[E2E] 시뮬레이션 거부",
        }, partnerToken);
        if (efResult.status !== 200) {
          throw new Error(`partner-reject-application EF returned ${efResult.status} for app ${appId}`);
        }
        log({ level: "info", phase: "approve", step: "ef_direct_reject", message: `Rejected app ${appId} via partner-reject-application EF` });

        const appAssertion = await simAssertApplicationRejected(supabase, appId);
        assertions.push(appAssertion);

        if (appAssertion.passed) {
          rejectedApplicationIds.push(appId);
          log({ level: "info", phase: "approve", step: "rejected", message: `App ${appId} directly rejected via EF (no verification required)` });
        } else {
          log({ level: "warn", phase: "approve", step: "rejected", message: `App ${appId} EF rejection assertion failed: ${appAssertion.details}` });
        }
      }
    } catch (e) {
      if (strict) throw e;
      log({ level: "error", phase: "approve", step: "reject_loop", message: `Unexpected error for app ${appId}: ${String(e)}` });
    }
  }

  log({
    level: "info",
    phase: "approve",
    step: "done",
    message: `Phase 3 complete: ${approvedApplicationIds.length} approved, ${rejectedApplicationIds.length} rejected`,
    data: { approvedCount: approvedApplicationIds.length, rejectedCount: rejectedApplicationIds.length },
  });

  return { approvedApplicationIds, rejectedApplicationIds, assertions };
}

// ─────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────

async function _fetchAppInfo(
  supabase: SupabaseClient,
  applicationId: string,
): Promise<{ eventId: string; userId: string } | null> {
  const { data: app, error } = await supabase
    .from("event_applications")
    .select("id, event_id, ticket_id, user_id, status")
    .eq("id", applicationId)
    .single();
  if (error || !app) return null;
  // deno-lint-ignore no-explicit-any
  const a = app as any;
  return { eventId: a.event_id, userId: a.user_id };
}

async function _fetchPartnerInfo(
  supabase: SupabaseClient,
  eventId: string,
): Promise<{ partnerId: string; requiredVerifIds: string[] } | null> {
  const { data: eventData, error } = await supabase
    .from("events")
    .select("id, parties!inner(partner_id, required_verification_ids)")
    .eq("id", eventId)
    .single();
  if (error || !eventData) return null;
  // deno-lint-ignore no-explicit-any
  const parties = (eventData as any)?.parties;
  const partnerInfo = Array.isArray(parties) ? parties[0] : parties;
  if (!partnerInfo) return null;
  return {
    partnerId: partnerInfo.partner_id,
    requiredVerifIds: partnerInfo.required_verification_ids ?? [],
  };
}

async function _resolveVerificationId(
  supabase: SupabaseClient,
  partnerId: string,
  requiredVerifIds: string[],
): Promise<string | null> {
  // Prefer required_verification_ids if available
  if (requiredVerifIds.length > 0) {
    return requiredVerifIds[0];
  }
  // Otherwise query any verification for this partner
  const { data: verifData } = await supabase
    .from("verifications")
    .select("id")
    .eq("partner_id", partnerId)
    .maybeSingle();
  return verifData?.id ?? null;
}
