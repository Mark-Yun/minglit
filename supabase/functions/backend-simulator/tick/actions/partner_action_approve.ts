// tick/actions/partner_action_approve.ts — PartnerActionApprove: approve a pending application (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * Partner approves a pending_review application.
 * EF: partner-approve-application
 * Verifies event_applications.status='approved' and event_participants row created.
 */
export class PartnerActionApprove extends SimAction {
  readonly type = "partner_approve";
  readonly ef = "partner-approve-application";
  readonly actorId: string;
  readonly description: string;

  private readonly applicationId: string;

  constructor(actorId: string, applicationId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.applicationId = applicationId;
    this.description = `partner[${actorId}] approves application[${applicationId}]`;
  }

  buildParams(): Record<string, unknown> {
    return { application_id: this.applicationId };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "partner_approve_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    return {
      passed: true,
      name: "partner_approve_ef_ok",
      details: `status 200`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    try {
      // Check application status is 'approved'
      const { data: appData, error: appErr } = await supabase
        .from("event_applications")
        .select("id, status, event_id, user_id")
        .eq("id", this.applicationId)
        .maybeSingle();

      if (appErr) {
        return {
          passed: false,
          name: "partner_approve_db_application",
          details: `query error: ${appErr.message}`,
        };
      }
      if (!appData) {
        return {
          passed: false,
          name: "partner_approve_db_application",
          details: `no event_applications row for id=${this.applicationId}`,
        };
      }
      if (appData.status !== "approved") {
        return {
          passed: false,
          name: "partner_approve_db_application_status",
          details: `expected status='approved', got '${appData.status}'`,
        };
      }

      // Check event_participants row was created
      const { data: participant, error: participantErr } = await supabase
        .from("event_participants")
        .select("id")
        .eq("event_id", appData.event_id as string)
        .eq("user_id", appData.user_id as string)
        .maybeSingle();

      if (participantErr) {
        return {
          passed: false,
          name: "partner_approve_db_participant",
          details: `query error: ${participantErr.message}`,
        };
      }
      if (!participant) {
        return {
          passed: false,
          name: "partner_approve_db_participant",
          details: `no event_participants row for event=${appData.event_id} user=${appData.user_id}`,
        };
      }

      return {
        passed: true,
        name: "partner_approve_db_ok",
        details: `application[${this.applicationId}] approved, participant[${participant.id}] created`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "partner_approve_db_error",
        details: String(e),
      };
    }
  }
}
