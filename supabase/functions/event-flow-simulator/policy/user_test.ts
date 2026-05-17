// v2/policy/user_test.ts — userPolicy 단위 테스트

import { assertEquals } from "@std/assert";
import { userPolicy } from "./user.ts";
import { createPRNG } from "../core/types.ts";
import type { Rates } from "../params/default.ts";
import { clearRegistry, registerAction } from "../action/_registry.ts";
import { applyAction } from "../action/apply.ts";

const baseRates: Rates = { user: { user_apply: 1.0 }, partner: {} };

function setup() {
  clearRegistry();
  registerAction(applyAction);
}

Deno.test({
  name: "userPolicy - returns null when no actions are executable",
  fn: () => {
    setup();
    const state = { myApplications: [], visibleEvents: [] };
    const action = userPolicy("user-1", state, baseRates, createPRNG(1));
    assertEquals(action, null);
  },
});

Deno.test({
  name: "userPolicy - returns apply action when applyAction is the only viable",
  fn: () => {
    setup();
    const state = {
      myApplications: [],
      visibleEvents: [{ id: "e1", tickets: [{ id: "t1" }] }],
    };
    const action = userPolicy("user-1", state, baseRates, createPRNG(1));
    assertEquals(action?.type, "user_apply");
    assertEquals(action?.ef, "apply-event");
    assertEquals(action?.actorId, "user-1");
    assertEquals(action?.payload.event_id, "e1");
    assertEquals(action?.payload.ticket_id, "t1");
  },
});

Deno.test({
  name: "userPolicy - returns null when totalWeight is 0",
  fn: () => {
    setup();
    const zeroRates: Rates = { user: { user_apply: 0 }, partner: {} };
    const state = {
      myApplications: [],
      visibleEvents: [{ id: "e1", tickets: [{ id: "t1" }] }],
    };
    const action = userPolicy("user-1", state, zeroRates, createPRNG(1));
    assertEquals(action, null);
  },
});

Deno.test({
  // Reproducibility 가드: 같은 seed = 같은 action
  name: "userPolicy - same seed produces same action (deterministic)",
  fn: () => {
    setup();
    const state = {
      myApplications: [],
      visibleEvents: [{ id: "e1", tickets: [{ id: "t1" }] }],
    };
    const a1 = userPolicy("user-1", state, baseRates, createPRNG(42));
    const a2 = userPolicy("user-1", state, baseRates, createPRNG(42));
    assertEquals(a1, a2);
  },
});
