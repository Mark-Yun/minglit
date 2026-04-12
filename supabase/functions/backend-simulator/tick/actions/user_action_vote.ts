// tick/actions/user_action_vote.ts — UserActionVote: cast a match vote (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * User casts a match vote for another checked-in participant during an ongoing event.
 * Verifies match_votes row exists for voter + candidate + event after EF call.
 */
export class UserActionVote extends SimAction {
  readonly type = "user_vote";
  readonly ef = "user-cast-vote";
  readonly actorId: string;
  readonly description: string;

  private readonly eventId: string;
  private readonly candidateId: string;

  constructor(actorId: string, eventId: string, candidateId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.eventId = eventId;
    this.candidateId = candidateId;
    this.description = `user[${actorId}] votes for candidate[${candidateId}] in event[${eventId}]`;
  }

  buildParams(): Record<string, unknown> {
    return { event_id: this.eventId, candidate_id: this.candidateId };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "vote_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    return {
      passed: true,
      name: "vote_ef_ok",
      details: `status 200`,
    };
  }

  async assertDBState(supabase: SupabaseClient): Promise<AssertionResult> {
    try {
      const { data, error } = await supabase
        .from("match_votes")
        .select("id")
        .eq("event_id", this.eventId)
        .eq("voter_id", this.actorId)
        .eq("candidate_id", this.candidateId)
        .maybeSingle();

      if (error) {
        return {
          passed: false,
          name: "vote_db_row",
          details: `query error: ${error.message}`,
        };
      }
      if (!data) {
        return {
          passed: false,
          name: "vote_db_row",
          details: `no match_votes row for voter=${this.actorId} candidate=${this.candidateId} event=${this.eventId}`,
        };
      }

      return {
        passed: true,
        name: "vote_db_ok",
        details: `match_votes row[${data.id}] exists`,
      };
    } catch (e) {
      return {
        passed: false,
        name: "vote_db_error",
        details: String(e),
      };
    }
  }
}
