// _shared/_testing/fixtures/ticket.ts — tickets row builder

export interface TicketFixture {
  id: string;
  event_id: string;
  name: string;
  price: number;
  quantity: number;
  sold_count: number;
  status: string;
  target_entry_group_ids: string[];
  required_verification_ids: string[];
}

const DEFAULTS: TicketFixture = {
  id: "tk-1",
  event_id: "ev-1",
  name: "General",
  price: 15000,
  quantity: 30,
  sold_count: 0,
  status: "on_sale",
  target_entry_group_ids: [],
  required_verification_ids: [],
};

export function buildTicket(overrides: Partial<TicketFixture> = {}): TicketFixture {
  return { ...DEFAULTS, ...overrides };
}
