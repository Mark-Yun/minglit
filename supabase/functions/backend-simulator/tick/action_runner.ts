// tick/action_runner.ts — ActionRunner: executes SimActions sequentially (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { ActionResult, LogFn } from "./tick_types.ts";
import type { SimAction } from "./sim_action.ts";
import { callEdgeFunction } from "../sim_auth.ts";

/**
 * Executes a list of SimActions sequentially: calls EF, validates response, checks DB state.
 */
export class ActionRunner {
  constructor(
    private supabase: SupabaseClient,
    private supabaseUrl: string,
    private log: LogFn,
  ) {}

  async execute(actions: SimAction[]): Promise<ActionResult[]> {
    const results: ActionResult[] = [];

    for (const action of actions) {
      try {
        // 1. Call EF
        const efRes = await callEdgeFunction(
          this.supabaseUrl,
          action.ef,
          action.buildParams(),
          action.token,
        );

        const efResponse = {
          status: efRes.status,
          data: (efRes.data ?? {}) as Record<string, unknown>,
        };

        // 2. Validate EF response
        const efAssertion = action.assertEFResponse(efResponse);

        // 3. Verify DB state
        const dbAssertion = await action.assertDBState(this.supabase);

        const passed = efAssertion.passed && dbAssertion.passed;

        this.log({
          level: passed ? "info" : "error",
          phase: "tick",
          step: action.type,
          message: `${action.description} → ${passed ? "✅" : "❌"}`,
          data: { efAssertion, dbAssertion },
        });

        results.push({
          actionType: action.type,
          description: action.description,
          passed,
          efAssertion,
          dbAssertion,
        });
      } catch (e) {
        this.log({
          level: "error",
          phase: "tick",
          step: action.type,
          message: `${action.description} → 💥 ${String(e)}`,
        });

        results.push({
          actionType: action.type,
          description: action.description,
          passed: false,
          error: e,
        });
      }
    }

    return results;
  }
}
