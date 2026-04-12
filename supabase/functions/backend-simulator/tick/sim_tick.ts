// tick/sim_tick.ts — Main tick() orchestrator for Continuous Tick Simulator (#1331)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { TickConfig, TickSummary, LogFn } from "./tick_types.ts";
import type { SimAction } from "./sim_action.ts";
import { DEFAULT_TICK_CONFIG } from "./tick_types.ts";
import { ActionRunner } from "./action_runner.ts";
import { UserActionFactory } from "./factories/user_action_factory.ts";
import { PartnerActionFactory } from "./factories/partner_action_factory.ts";
import { getSimUserToken, getSimPartnerToken, getPartnerEmail } from "../sim_auth.ts";

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/**
 * Executes a single simulation tick:
 * 1. Discovers E2E partners and a random sample of sim users
 * 2. Generates partner actions (approve/reject pending apps, create event if low)
 * 3. Generates user actions (discover feed, apply, refund, checkin)
 * 4. Shuffles all actions to simulate interleaved real-world activity
 * 5. Executes via ActionRunner and returns a TickSummary
 */
export async function tick(
  supabase: SupabaseClient,
  supabaseUrl: string,
  anonKey: string,
  log: LogFn,
  config: TickConfig = DEFAULT_TICK_CONFIG,
): Promise<TickSummary> {
  const simUserPassword = Deno.env.get("SIM_USER_PASSWORD");
  if (!simUserPassword) {
    throw new Error("SIM_USER_PASSWORD not set");
  }

  // 1. Discover E2E partners via their [E2E]-prefixed party titles
  const { data: e2eParties } = await supabase
    .from("parties")
    .select("partner_id")
    .like("title", "[E2E]%");

  const partnerIdRows = (e2eParties ?? []) as { partner_id: string }[];
  const partnerIds = [...new Set(partnerIdRows.map((p) => p.partner_id))];

  log({
    level: "info",
    phase: "tick",
    step: "init",
    message: `Found ${partnerIds.length} E2E partners`,
  });

  // 2. Discover sim users (identified by username prefix 'sim_')
  const { data: e2eUsers } = await supabase
    .from("user_profiles")
    .select("id, username")
    .like("username", "sim_%")
    .limit(60);

  const userRows = (e2eUsers ?? []) as { id: string; username: string }[];
  const allUsers = userRows.map((u) => ({ id: u.id, username: u.username }));
  const tickUsers = shuffle(allUsers).slice(0, config.usersPerTick);

  log({
    level: "info",
    phase: "tick",
    step: "init",
    message: `Selected ${tickUsers.length}/${allUsers.length} users for this tick`,
  });

  // 3. Generate partner actions
  const allActions: SimAction[] = [];

  for (const partnerId of partnerIds) {
    try {
      const partnerEmail = await getPartnerEmail(supabase, partnerId);
      if (!partnerEmail) {
        log({
          level: "warn",
          phase: "tick",
          step: "partner_auth",
          message: `No email found for partner ${partnerId}`,
        });
        continue;
      }
      const token = await getSimPartnerToken(
        supabaseUrl,
        anonKey,
        partnerEmail,
        simUserPassword,
      );
      const factory = new PartnerActionFactory(partnerId, token, config);
      const actions = await factory.generate(supabase);
      allActions.push(...actions);
    } catch (e) {
      log({
        level: "error",
        phase: "tick",
        step: "partner_factory",
        message: `Partner ${partnerId}: ${String(e)}`,
      });
    }
  }

  // 4. Generate user actions
  for (const user of tickUsers) {
    try {
      const { data: authData } = await supabase.auth.admin.getUserById(user.id);
      const email = authData?.user?.email;
      if (!email) {
        log({
          level: "warn",
          phase: "tick",
          step: "user_auth",
          message: `No email for user ${user.id}`,
        });
        continue;
      }
      const token = await getSimUserToken(
        supabaseUrl,
        anonKey,
        email,
        simUserPassword,
      );
      const factory = new UserActionFactory(user.id, token, supabaseUrl, config);
      const actions = await factory.generate(supabase);
      allActions.push(...actions);
    } catch (e) {
      log({
        level: "error",
        phase: "tick",
        step: "user_factory",
        message: `User ${user.id}: ${String(e)}`,
      });
    }
  }

  log({
    level: "info",
    phase: "tick",
    step: "generate",
    message: `Generated ${allActions.length} actions`,
  });

  // 5. Shuffle and execute all actions
  const shuffled = shuffle(allActions);
  const runner = new ActionRunner(supabase, supabaseUrl, log);
  const results = await runner.execute(shuffled);

  // 6. Build summary
  const failures = results.filter((r) => !r.passed);
  const summary: TickSummary = {
    total_actions: results.length,
    passed: results.filter((r) => r.passed).length,
    failed: failures.length,
    actors: {
      partners: partnerIds.length,
      users: tickUsers.length,
    },
    results,
  };

  log({
    level: failures.length > 0 ? "error" : "info",
    phase: "tick",
    step: "summary",
    message: `Tick complete: ${summary.passed}/${summary.total_actions} passed, ${summary.failed} failed`,
  });

  return summary;
}
