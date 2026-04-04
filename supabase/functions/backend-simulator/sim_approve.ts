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
 *   3. If verification needed: create submission → update status → trigger fires
 *   4. If no verification: directly update application.status
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
        // Verification flow: insert submission → update to approved → trigger fires
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

        // Attempt to approve via partner-review-submission EF; fall back to direct DB update
        if (supabaseUrl && anonKey && partnerId) {
          const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
          try {
            const partnerEmail = await getPartnerEmail(supabase, partnerId);
            if (partnerEmail) {
              const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
              const efResult = await callEdgeFunction(supabaseUrl, "partner-review-submission", {
                action: "review",
                submission_id: submissionId,
                result: "approved",
              }, partnerToken);
              if (efResult.status === 200) {
                log({ level: "info", phase: "approve", step: "ef_approve", message: `Approved submission ${submissionId} via EF` });
                // EF handled the status update — skip direct DB update, continue to assertions below
              } else {
                throw new Error(`EF returned ${efResult.status}`);
              }
            } else {
              throw new Error("Partner email not found");
            }
          } catch (efErr) {
            if (strict) {
              throw new Error(`Strict mode: EF failed for submission ${submissionId} (app ${appId}): ${String(efErr)}`);
            }
            log({ level: "warn", phase: "approve", step: "ef_approve_fallback", message: `EF failed, falling back to direct update: ${String(efErr)}` });
            const { error: updErr } = await supabase
              .from("verification_submissions")
              .update({ status: "approved" })
              .eq("id", submissionId);
            if (updErr) {
              log({ level: "error", phase: "approve", step: "update_submission", message: `Failed to approve submission ${submissionId}: ${updErr.message}` });
              continue;
            }
          }
        } else {
          // No EF credentials — use direct DB update
          const { error: updErr } = await supabase
            .from("verification_submissions")
            .update({ status: "approved" })
            .eq("id", submissionId);
          if (updErr) {
            log({ level: "error", phase: "approve", step: "update_submission", message: `Failed to approve submission ${submissionId}: ${updErr.message}` });
            continue;
          }
        }

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
        // No verification needed: directly update application status
        const { error: updErr } = await supabase
          .from("event_applications")
          .update({ status: "approved" })
          .eq("id", appId);
        if (updErr) {
          log({ level: "error", phase: "approve", step: "direct_approve", message: `Failed to directly approve app ${appId}: ${updErr.message}` });
          continue;
        }

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
        // Verification flow: insert submission → update to rejected → trigger fires
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

        // Attempt to reject via partner-review-submission EF; fall back to direct DB update
        if (supabaseUrl && anonKey && partnerId) {
          const simUserPassword = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
          try {
            const partnerEmail = await getPartnerEmail(supabase, partnerId);
            if (partnerEmail) {
              const partnerToken = await getSimPartnerToken(supabaseUrl, anonKey, partnerEmail, simUserPassword);
              const efResult = await callEdgeFunction(supabaseUrl, "partner-review-submission", {
                action: "review",
                submission_id: submissionId,
                result: "rejected",
              }, partnerToken);
              if (efResult.status === 200) {
                log({ level: "info", phase: "approve", step: "ef_reject", message: `Rejected submission ${submissionId} via EF` });
                // EF handled the status update — skip direct DB update, continue to assertions below
              } else {
                throw new Error(`EF returned ${efResult.status}`);
              }
            } else {
              throw new Error("Partner email not found");
            }
          } catch (efErr) {
            if (strict) {
              throw new Error(`Strict mode: EF failed for submission ${submissionId} (app ${appId}): ${String(efErr)}`);
            }
            log({ level: "warn", phase: "approve", step: "ef_reject_fallback", message: `EF failed, falling back to direct update: ${String(efErr)}` });
            const { error: updErr } = await supabase
              .from("verification_submissions")
              .update({ status: "rejected" })
              .eq("id", submissionId);
            if (updErr) {
              log({ level: "error", phase: "approve", step: "update_submission", message: `Failed to reject submission ${submissionId}: ${updErr.message}` });
              continue;
            }
          }
        } else {
          // No EF credentials — use direct DB update
          const { error: updErr } = await supabase
            .from("verification_submissions")
            .update({ status: "rejected" })
            .eq("id", submissionId);
          if (updErr) {
            log({ level: "error", phase: "approve", step: "update_submission", message: `Failed to reject submission ${submissionId}: ${updErr.message}` });
            continue;
          }
        }

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
        // No verification needed: directly update application status
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
          log({ level: "info", phase: "approve", step: "rejected", message: `App ${appId} directly rejected (no verification required)` });
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
