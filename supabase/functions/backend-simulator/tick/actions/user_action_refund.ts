// tick/actions/user_action_refund.ts — UserActionRefund: cancel an event application (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * User cancels an existing event application and requests a refund.
 * Verifies application.status='cancelled' and participant row removed.
 */
export class UserActionRefund extends SimAction {
  readonly type = "user_refund";
  readonly ef = "user-cancel-order";
  readonly actorId: string;
  readonly description: string;

  private readonly applicationId: string;
  private readonly eventId: string;

  constructor(actorId: string, applicationId: string, eventId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.applicationId = applicationId;
    this.eventId = eventId;
    this.description = `user[${actorId}] refunds application[${applicationId}] for event[${eventId}]`;
  }

  buildParams(): Record<string, unknown> {
    return { event_id: this.eventId };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "refund_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    return {
      passed: true,
      name: "refund_ef_ok",
      details: `status 200`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    try {
      // Check application status is cancelled
      const { data: appData, error: appError } = await supabase
        .from("event_applications")
        .select("status")
        .eq("id", this.applicationId)
        .maybeSingle();

      if (appError) {
        return {
          passed: false,
          name: "refund_db_application",
          details: `query error: ${appError.message}`,
        };
      }
      if (!appData) {
        return {
          passed: false,
          name: "refund_db_application",
          details: `no event_applications row for id=${this.applicationId}`,
        };
      }
      if (appData.status !== "cancelled") {
        return {
          passed: false,
          name: "refund_db_application_status",
          details: `expected status='cancelled', got '${appData.status}'`,
        };
      }

      // Check participant row is removed
      const { data: participantData, error: participantError } = await supabase
        .from("event_participants")
        .select("id")
        .eq("event_id", this.eventId)
        .eq("user_id", this.actorId)
        .maybeSingle();

      if (participantError) {
        return {
          passed: false,
          name: "refund_db_participant",
          details: `query error: ${participantError.message}`,
        };
      }
      if (participantData) {
        return {
          passed: false,
          name: "refund_db_participant_removed",
          details: `event_participants row still exists for user=${this.actorId} event=${this.eventId}`,
        };
      }

      return {
        passed: true,
        name: "refund_db_ok",
        details: `application cancelled, participant row removed`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "refund_db_error",
        details: String(e),
      };
    }
  }
}
