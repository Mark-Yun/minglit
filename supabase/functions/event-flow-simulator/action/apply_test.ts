// v2/action/apply_test.ts — applyAction 단위 테스트

import { assertEquals, assertThrows } from "@std/assert";
import { applyAction } from "./apply.ts";
import { createPRNG } from "../core/types.ts";
import type { ObservableState } from "../core/observable.ts";

const rng = createPRNG(42);

function stateWith(opts: {
  apps?: Array<{ event_id: string }>;
  events?: Array<{
    id: string;
    status?: string;
    tickets?: Array<{
      id: string;
      status?: string;
      quantity?: number;
      sold_count?: number;
    }>;
  }>;
}): ObservableState {
  return {
    myApplications: opts.apps ?? [],
    visibleEvents: opts.events ?? [],
  };
}

function ticket(
  id: string,
  overrides: Partial<{ status: string; quantity: number; sold_count: number }> =
    {},
) {
  return { id, status: "on_sale", quantity: 10, sold_count: 0, ...overrides };
}

function event(
  id: string,
  ticketId: string,
  overrides: Partial<{
    status: string;
    tickets: ReturnType<typeof ticket>[];
  }> = {},
) {
  return {
    id,
    status: "scheduled",
    tickets: [ticket(ticketId)],
    ...overrides,
  };
}

Deno.test({
  name: "applyAction.canExecute - false when no visible events",
  fn: () => {
    assertEquals(applyAction.canExecute(stateWith({})), false);
  },
});

Deno.test({
  name: "applyAction.canExecute - false when all events already applied",
  fn: () => {
    const state = stateWith({
      events: [event("e1", "t1")],
      apps: [{ event_id: "e1" }],
    });
    assertEquals(applyAction.canExecute(state), false);
  },
});

Deno.test({
  name: "applyAction.canExecute - false when candidate event has no tickets",
  fn: () => {
    const state = stateWith({
      events: [event("e1", "t1", { tickets: [] })],
    });
    assertEquals(applyAction.canExecute(state), false);
  },
});

Deno.test({
  name:
    "applyAction.canExecute - true when unapplied event with tickets exists",
  fn: () => {
    const state = stateWith({
      events: [event("e1", "t1")],
      apps: [],
    });
    assertEquals(applyAction.canExecute(state), true);
  },
});

Deno.test({
  name: "applyAction.canExecute - true when active event is application-open",
  fn: () => {
    const state = stateWith({
      events: [event("e1", "t1", { status: "active" })],
      apps: [],
    });
    assertEquals(applyAction.canExecute(state), true);
  },
});

Deno.test({
  name: "applyAction.canExecute - false when event is not application-open",
  fn: () => {
    const state = stateWith({
      events: [event("e1", "t1", { status: "cancelled" })],
      apps: [],
    });
    assertEquals(applyAction.canExecute(state), false);
  },
});

Deno.test({
  name: "applyAction.canExecute - false when tickets are unavailable",
  fn: () => {
    const state = stateWith({
      events: [
        event("e1", "t1", { tickets: [ticket("t1", { status: "closed" })] }),
        event("e2", "t2", {
          tickets: [ticket("t2", { quantity: 10, sold_count: 10 })],
        }),
      ],
      apps: [],
    });
    assertEquals(applyAction.canExecute(state), false);
  },
});

Deno.test({
  name:
    "applyAction.buildPayload - returns event_id + ticket_id from a candidate",
  fn: () => {
    const state = stateWith({
      events: [
        event("e1", "t1"),
        event("e2", "t2"),
      ],
    });
    const payload = applyAction.buildPayload(state, rng);
    // 후보 중 하나여야 함 (deterministic PRNG seed=42)
    assertEquals(["e1", "e2"].includes(payload.event_id as string), true);
    const expectedTicket = payload.event_id === "e1" ? "t1" : "t2";
    assertEquals(payload.ticket_id, expectedTicket);
  },
});

Deno.test({
  name: "applyAction.buildPayload - skips already-applied events",
  fn: () => {
    const state = stateWith({
      events: [
        event("e1", "t1"),
        event("e2", "t2"),
      ],
      apps: [{ event_id: "e1" }],
    });
    const payload = applyAction.buildPayload(state, rng);
    assertEquals(payload.event_id, "e2");
    assertEquals(payload.ticket_id, "t2");
  },
});

Deno.test({
  name: "applyAction.buildPayload - skips unavailable tickets",
  fn: () => {
    const state = stateWith({
      events: [
        event("e1", "t1", { tickets: [ticket("t1", { status: "closed" })] }),
        event("e2", "t2"),
      ],
    });
    const payload = applyAction.buildPayload(state, rng);
    assertEquals(payload.event_id, "e2");
    assertEquals(payload.ticket_id, "t2");
  },
});

Deno.test({
  name:
    "applyAction.buildPayload - throws when no candidate (canExecute should gate)",
  fn: () => {
    const state = stateWith({});
    assertThrows(
      () => applyAction.buildPayload(state, rng),
      Error,
      "canExecute",
    );
  },
});

Deno.test({
  name: "applyAction - identity fields",
  fn: () => {
    assertEquals(applyAction.type, "user_apply");
    assertEquals(applyAction.role, "user");
    assertEquals(applyAction.ef, "apply-event");
  },
});
