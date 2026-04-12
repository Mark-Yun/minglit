// tick/tick_types.ts — Core types for the Continuous Tick Simulator (#1331)

import type { SimLogEntry } from "../sim_types.ts";

/** Configuration for tick-based simulation */
export interface TickConfig {
  usersPerTick: number;        // Users acting per tick (default 10)
  negativeRate: number;        // Refund probability (default 0.1)
  checkinRate: number;         // Attendance probability (default 0.9)
  maxAppsPerUser: number;      // Max applications per user (default 3)
  minScheduledEvents: number;  // Min scheduled events per partner (default 2)
}

export const DEFAULT_TICK_CONFIG: TickConfig = {
  usersPerTick: 10,
  negativeRate: 0.1,
  checkinRate: 0.9,
  maxAppsPerUser: 3,
  minScheduledEvents: 2,
};

/** Single assertion check result (used by actions) */
export interface AssertionResult {
  passed: boolean;
  name: string;
  details: string;
}

/** Result of a single action execution */
export interface ActionResult {
  actionType: string;
  description: string;
  passed: boolean;
  efAssertion?: AssertionResult;
  dbAssertion?: AssertionResult;
  error?: unknown;
}

/** EF response wrapper */
export interface EFResponse {
  status: number;
  data: Record<string, unknown>;
}

/** Tick execution summary */
export interface TickSummary {
  total_actions: number;
  passed: number;
  failed: number;
  actors: {
    partners: number;
    users: number;
  };
  results: ActionResult[];
}

export type LogFn = (entry: Omit<SimLogEntry, "timestamp">) => void;
