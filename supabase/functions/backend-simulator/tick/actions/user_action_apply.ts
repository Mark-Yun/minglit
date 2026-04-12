// tick/actions/user_action_apply.ts — UserActionApplyEvent: apply to an event (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * User applies to an event with a specific ticket.
 * Verifies application row exists in the DB with an accepted status.
 */
export class UserActionApplyEvent extends SimAction {
  readonly type = "user_apply";
  readonly ef = "apply-event";
  readonly actorId: string;
  readonly description: string;

  private readonly eventId: string;
  private readonly ticketId: string;

  constructor(actorId: string, eventId: string, ticketId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.eventId = eventId;
    this.ticketId = ticketId;
    this.description = `user[${actorId}] applies to event[${eventId}]`;
  }

  buildParams(): Record<string, unknown> {
    return { event_id: this.eventId, ticket_id: this.ticketId };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "apply_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    if (!response.data?.application_id) {
      return {
        passed: false,
        name: "apply_ef_application_id",
        details: `data.application_id is missing`,
      };
    }
    return {
      passed: true,
      name: "apply_ef_ok",
      details: `status 200, application_id=${response.data.application_id}`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    try {
      const { data, error } = await supabase
        .from("event_applications")
        .select("id, status")
        .eq("user_id", this.actorId)
        .eq("event_id", this.eventId)
        .maybeSingle();

      if (error) {
        return {
          passed: false,
          name: "apply_db_row",
          details: `query error: ${error.message}`,
        };
      }
      if (!data) {
        return {
          passed: false,
          name: "apply_db_row",
          details: `no event_applications row for user=${this.actorId} event=${this.eventId}`,
        };
      }

      const validStatuses = ["paid", "pending_review"];
      if (!validStatuses.includes(data.status as string)) {
        return {
          passed: false,
          name: "apply_db_status",
          details: `expected status in (paid, pending_review), got '${data.status}'`,
        };
      }

      return {
        passed: true,
        name: "apply_db_ok",
        details: `application[${data.id}] status=${data.status}`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "apply_db_error",
        details: String(e),
      };
    }
  }
}
