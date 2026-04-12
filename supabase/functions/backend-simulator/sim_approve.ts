// sim_approve.ts — Phase 3: Partner Approval + Error Scenarios

import type { SupabaseClient } from "@supabase/supabase-js";
import type { SimLogEntry, SimAssertionResult } from "./sim_types.ts";
import {
  simAssertVerificationApproved,
  simAssertApplicationApproved,
  simAssertApplicationRejected,
} from "./sim_assertions.ts";
import { getSimPartnerToken, getPartnerEmail, callEdgeFunction } from "./sim_auth.ts";

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
        // Verification flow: insert submission → call partner-review-submission EF
        const submissionId = crypto.randomUUID();
        const { error: insErr } = await supabase.from("verification_submissions").insert({
          id: submissionId,
          partner_id: partnerId,
          user_id: userId,
          verification_id: verificationId,
          application_id: appId,
          status: "pending",
          snapshot_data: {},
        });
        if (insErr) {
          log({ level: "error", phase: "approve", step: "insert_submission", message: `Failed to insert submission for app ${appId}: ${insErr.message}` });
          continue;
        }

        // Call partner-review-submission EF — no fallback. EF is the only path.
        // Fix #1280: remove direct DB fallback; EF failure is always an error.
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
        const partnerEmail = await getPartnerEmail(supabase, partnerId);
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (submission ${submissionId}, app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl!, anonKey!, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl!, "partner-review-submission", {
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
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
        const partnerEmail = partnerId ? await getPartnerEmail(supabase, partnerId) : null;
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl!, anonKey!, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl!, "partner-approve-application", {
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
        // Verification flow: insert submission → call partner-review-submission EF
        const submissionId = crypto.randomUUID();
        const { error: insErr } = await supabase.from("verification_submissions").insert({
          id: submissionId,
          partner_id: partnerId,
          user_id: userId,
          verification_id: verificationId,
          application_id: appId,
          status: "pending",
          snapshot_data: {},
        });
        if (insErr) {
          log({ level: "error", phase: "approve", step: "insert_submission", message: `Failed to insert submission for app ${appId}: ${insErr.message}` });
          continue;
        }

        // Call partner-review-submission EF — no fallback. EF is the only path.
        // Fix #1280: remove direct DB fallback; EF failure is always an error.
        const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
        const partnerEmail = await getPartnerEmail(supabase, partnerId);
        if (!partnerEmail) {
          throw new Error(`Partner email not found for partner ${partnerId} (submission ${submissionId}, app ${appId})`);
        }
        const partnerToken = await getSimPartnerToken(supabaseUrl!, anonKey!, partnerEmail, simUserPassword);
        const efResult = await callEdgeFunction(supabaseUrl!, "partner-review-submission", {
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
        // No verification needed: reject via direct DB update.
        // Fix #1280: partner-approve-application EF does not support a "reject" action,
        // and there is no partner-reject-application EF. Direct DB update is intentional
        // until a dedicated reject EF is introduced.
        const { error: updErr } = await supabase
          .from("event_applications")
          .update({ status: "rejected" })
          .eq("id", appId);
        if (updErr) {
          log({ level: "error", phase: "approve", step: "direct_reject", message: `Failed to directly reject app ${appId}: ${updErr.message}` });
          continue;
        }

        const appAssertion = await simAssertApplicationRejected(supabase, appId);
        assertions.push(appAssertion);

        if (appAssertion.passed) {
          rejectedApplicationIds.push(appId);
          log({ level: "info", phase: "approve", step: "rejected", message: `App ${appId} directly rejected (no verification required, no reject EF available)` });
        } else {
          log({ level: "warn", phase: "approve", step: "rejected", message: `App ${appId} direct rejection assertion failed: ${appAssertion.details}` });
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
