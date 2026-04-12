// tick/actions/partner_action_reject.ts — PartnerActionReject: reject a pending application (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * Partner rejects a pending_review application.
 * EF: partner-reject-application
 * Verifies event_applications.status='rejected'.
 */
export class PartnerActionReject extends SimAction {
  readonly type = "partner_reject";
  readonly ef = "partner-reject-application";
  readonly actorId: string;
  readonly description: string;

  private readonly applicationId: string;

  constructor(actorId: string, applicationId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.applicationId = applicationId;
    this.description = `partner[${actorId}] rejects application[${applicationId}]`;
  }

  buildParams(): Record<string, unknown> {
    return { application_id: this.applicationId };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "partner_reject_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    return {
      passed: true,
      name: "partner_reject_ef_ok",
      details: `status 200`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    try {
      const { data: appData, error: appErr } = await supabase
        .from("event_applications")
        .select("id, status")
        .eq("id", this.applicationId)
        .maybeSingle();

      if (appErr) {
        return {
          passed: false,
          name: "partner_reject_db_application",
          details: `query error: ${appErr.message}`,
        };
      }
      if (!appData) {
        return {
          passed: false,
          name: "partner_reject_db_application",
          details: `no event_applications row for id=${this.applicationId}`,
        };
      }
      if (appData.status !== "rejected") {
        return {
          passed: false,
          name: "partner_reject_db_application_status",
          details: `expected status='rejected', got '${appData.status}'`,
        };
      }

      return {
        passed: true,
        name: "partner_reject_db_ok",
        details: `application[${this.applicationId}] status='rejected'`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "partner_reject_db_error",
        details: String(e),
      };
    }
  }
}
