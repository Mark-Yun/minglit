// tick/actions/user_action_discover.ts — UserActionDiscover: browse event feed (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "../tick_types.ts";
import { SimAction } from "../sim_action.ts";

/**
 * User browses the event discovery feed.
 * Read-only action — no DB state change expected.
 */
export class UserActionDiscover extends SimAction {
  readonly type = "user_discover";
  readonly ef = "user-event-feed";
  readonly actorId: string;
  readonly description: string;

  constructor(actorId: string, token: string) {
    super(token);
    this.actorId = actorId;
    this.description = `user[${actorId}] discovers events via feed`;
  }

  buildParams(): Record<string, unknown> {
    return { limit: 20 };
  }

  assertEFResponse(response: EFResponse): AssertionResult {
    if (response.status !== 200) {
      return {
        passed: false,
        name: "discover_ef_status",
        details: `expected status 200, got ${response.status}`,
      };
    }
    if (!Array.isArray(response.data?.events)) {
      return {
        passed: false,
        name: "discover_ef_events",
        details: `data.events is missing or not an array`,
      };
    }
    return {
      passed: true,
      name: "discover_ef_ok",
      details: `status 200, events count=${response.data.events.length}`,
    };
  }

  async assertDBState(_supabase: SupabaseClient): Promise<AssertionResult> {
    // Read-only action: no DB mutation to verify
    return {
      passed: true,
      name: "discover_db_skip",
      details: "read-only action, no DB assertion required",
    };
  }
}
