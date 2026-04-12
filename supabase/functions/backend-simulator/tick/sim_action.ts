// tick/sim_action.ts — Abstract base class for all tick simulator actions (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AssertionResult, EFResponse } from "./tick_types.ts";

/**
 * Abstract base for all tick simulator actions.
 * Each action knows how to build EF params, validate EF response, and verify DB state.
 */
export abstract class SimAction {
  abstract readonly type: string;
  abstract readonly ef: string;
  abstract readonly actorId: string;
  abstract readonly description: string;

  readonly token: string;

  constructor(token: string) {
    this.token = token;
  }

  /** Build the request payload for the Edge Function call */
  abstract buildParams(): Record<string, unknown>;

  /** Validate the EF HTTP response */
  abstract assertEFResponse(response: EFResponse): AssertionResult;

  /** Verify DB state after the action executed */
  abstract assertDBState(supabase: SupabaseClient): Promise<AssertionResult>;
}
