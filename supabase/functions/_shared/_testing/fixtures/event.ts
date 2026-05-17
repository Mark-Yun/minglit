// _shared/_testing/fixtures/event.ts — events row builder

export interface EventFixture {
  id: string;
  party_id: string;
  status: string;
  start_time: string;
  end_time: string;
  max_participants: number;
  current_participants: number;
  title: string;
}

const DEFAULTS: EventFixture = {
  id: "ev-1",
  party_id: "py-1",
  status: "scheduled",
  start_time: "2026-12-31T18:00:00Z",
  end_time: "2026-12-31T22:00:00Z",
  max_participants: 30,
  current_participants: 0,
  title: "Test Event",
};

export function buildEvent(overrides: Partial<EventFixture> = {}): EventFixture {
  return { ...DEFAULTS, ...overrides };
}
