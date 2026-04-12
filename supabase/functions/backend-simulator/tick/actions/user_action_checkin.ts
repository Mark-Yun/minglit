// tick/actions/user_action_checkin.ts — UserActionCheckin: check in to an event (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * User checks in to an active event using their participant record.
 * Verifies event_participants.status='checked_in' after EF call.
 */
export class UserActionCheckin extends SimAction {
  readonly type = "user_checkin";
  readonly ef = "event-checkin";
  readonly actorId: string;
  readonly description: string;

  private readonly eventId: string;
  private readonly participantId: string;

  constructor(actorId: string, eventId: string, participantId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.eventId = eventId;
    this.participantId = participantId;
    this.description = `user[${actorId}] checks in to event[${eventId}]`;
  }

  buildParams(): Record<string, unknown> {
    return { event_id: this.eventId, participant_id: this.participantId };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "checkin_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    return {
      passed: true,
      name: "checkin_ef_ok",
      details: `status 200`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    try {
      const { data, error } = await supabase
        .from("event_participants")
        .select("status")
        .eq("id", this.participantId)
        .maybeSingle();

      if (error) {
        return {
          passed: false,
          name: "checkin_db_participant",
          details: `query error: ${error.message}`,
        };
      }
      if (!data) {
        return {
          passed: false,
          name: "checkin_db_participant",
          details: `no event_participants row for id=${this.participantId}`,
        };
      }
      if (data.status !== "checked_in") {
        return {
          passed: false,
          name: "checkin_db_status",
          details: `expected status='checked_in', got '${data.status}'`,
        };
      }

      return {
        passed: true,
        name: "checkin_db_ok",
        details: `participant[${this.participantId}] status=checked_in`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "checkin_db_error",
        details: String(e),
      };
    }
  }
}
