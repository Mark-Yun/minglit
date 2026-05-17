// _shared/_testing/fixtures/application.ts — event_applications row builder

export interface ApplicationFixture {
  id: string;
  user_id: string;
  event_id: string;
  status: string;
  payment_id: string | null;
  payment_amount: number | null;
  paid_at: string | null;
  refund_status: string;
  refund_amount: number | null;
  created_at: string;
  updated_at: string;
}

const DEFAULTS: ApplicationFixture = {
  id: "app-1",
  user_id: "u-1",
  event_id: "ev-1",
  status: "pending",
  payment_id: null,
  payment_amount: 15000,
  paid_at: null,
  refund_status: "none",
  refund_amount: null,
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-01T00:00:00Z",
};

export function buildApplication(overrides: Partial<ApplicationFixture> = {}): ApplicationFixture {
  return { ...DEFAULTS, ...overrides };
}
