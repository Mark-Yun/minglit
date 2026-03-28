// sim_types.ts — E2E Simulation Type Definitions

export interface SimConfig {
  error_rate: number;         // 0-1, 20% = 0.2
  refund_rate: number;        // 0-1, 20% = 0.2
  party_count: number;        // number of new E2E parties to create
  events_per_party: number;   // events per party
  apps_per_event: number;     // applications per event
  checkin_rate: number;       // 0-1, 70% = 0.7
  no_show_rate: number;       // 0-1, 30% = 0.3
}

export interface SimPhaseResult {
  phase_name: string;
  duration_ms: number;
  log_entries: SimLogEntry[];
  assertions: SimAssertionResult[];
}

export interface SimRun {
  run_id: string;
  started_at: string;         // ISO timestamp
  config: SimConfig;
  phases: SimPhaseResult[];
}

export interface SimAssertionResult {
  check_name: string;
  passed: boolean;
  expected: unknown;
  actual: unknown;
  details?: string;
}

export interface SimSummary {
  total_checks: number;
  passed: number;
  failed: number;
  assertion_results: SimAssertionResult[];
}

export interface SimLogEntry {
  timestamp: string;          // ISO timestamp
  level: 'info' | 'warn' | 'error';
  phase: string;
  step: string;
  message: string;
  data?: unknown;
}

export interface SimRefundCalc {
  refund_percentage: number;  // 0, 50, 80, or 100
  refund_amount: number;      // floor(payment * percentage / 100)
  fee_amount: number;         // payment - refund_amount
}
