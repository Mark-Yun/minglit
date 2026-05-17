// v2/core/cascade_test.ts — runCascade 엔진 단위 테스트

import { assertEquals } from "@std/assert";
import { runCascade, type Transport } from "./cascade.ts";
import { createPRNG } from "./types.ts";
import type { Action } from "./types.ts";
import type { WorldSnapshot } from "./observable.ts";
import { defaultRates } from "../params/default.ts";
import { clearRegistry, registerAction } from "../action/_registry.ts";
import { applyAction } from "../action/apply.ts";

function emptySnapshot(): WorldSnapshot {
  return {
    parties: [],
    events: [],
    applications: [],
    participants: [],
    votes: [],
    blocks: [],
  };
}

function snapshotWithOneEvent(): WorldSnapshot {
  const snap = emptySnapshot();
  snap.parties.push({ id: "p1", partner_id: "partner-1", status: "active" });
  snap.events.push({
    id: "e1",
    party_id: "p1",
    status: "scheduled",
    start_time: new Date(Date.now() + 7 * 86400_000).toISOString(),
    tickets: [{ id: "t1", price: 0 }],
  });
  return snap;
}

/** Record-only transport — captures actions, always returns 200 OK */
function recordingTransport(): { transport: Transport; calls: Action[] } {
  const calls: Action[] = [];
  return {
    transport: {
      execute(action) {
        calls.push(action);
        return Promise.resolve({ ok: true, status: 200 });
      },
    },
    calls,
  };
}

Deno.test({
  name: "runCascade - empty actor list produces empty trace",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const { transport } = recordingTransport();
    const { trace } = await runCascade({
      actors: [],
      initialSnapshot: emptySnapshot(),
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 5,
    });
    assertEquals(trace.length, 0);
  },
});

Deno.test({
  name: "runCascade - user with no available actions skips tick (null policy)",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const { transport, calls } = recordingTransport();
    await runCascade({
      actors: [{ id: "user-1", role: "user" }],
      initialSnapshot: emptySnapshot(),  // no events → applyAction.canExecute=false
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 3,
    });
    assertEquals(calls.length, 0);
  },
});

Deno.test({
  name: "runCascade - records trace entry per executed action",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const { transport, calls } = recordingTransport();
    const { trace } = await runCascade({
      actors: [{ id: "user-1", role: "user" }],
      initialSnapshot: snapshotWithOneEvent(),
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 1,
    });
    assertEquals(calls.length, 1);
    assertEquals(trace.length, 1);
    assertEquals(trace[0].action.type, "user_apply");
    assertEquals(trace[0].action.ef, "apply-event");
    assertEquals(trace[0].status, 200);
    assertEquals(trace[0].ok, true);
  },
});

Deno.test({
  name: "runCascade - records error in trace when transport fails",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const failingTransport: Transport = {
      execute: () => Promise.resolve({ ok: false, status: 500, error: "boom" }),
    };
    const { trace } = await runCascade({
      actors: [{ id: "user-1", role: "user" }],
      initialSnapshot: snapshotWithOneEvent(),
      rates: defaultRates,
      transport: failingTransport,
      rng: createPRNG(1),
      ticks: 1,
    });
    assertEquals(trace.length, 1);
    assertEquals(trace[0].ok, false);
    assertEquals(trace[0].status, 500);
    assertEquals(trace[0].error, "boom");
  },
});

Deno.test({
  name: "runCascade - refreshSnapshot callback advances world state between ticks",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const { transport } = recordingTransport();
    let refreshCalls = 0;
    await runCascade({
      actors: [{ id: "user-1", role: "user" }],
      initialSnapshot: snapshotWithOneEvent(),
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 3,
      refreshSnapshot: (cur, _trace) => {
        refreshCalls++;
        return cur;
      },
    });
    assertEquals(refreshCalls, 3, "refreshSnapshot must be invoked after each tick");
  },
});

Deno.test({
  // Reproducibility 가드
  name: "runCascade - same seed produces same trace (deterministic)",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const t1 = recordingTransport();
    const t2 = recordingTransport();
    const cfg = (rt: Transport) => ({
      actors: [{ id: "user-1", role: "user" as const }],
      initialSnapshot: snapshotWithOneEvent(),
      rates: defaultRates,
      transport: rt,
      rng: createPRNG(99),
      ticks: 2,
    });
    const { trace: trace1 } = await runCascade(cfg(t1.transport));
    const { trace: trace2 } = await runCascade(cfg(t2.transport));
    assertEquals(trace1, trace2);
  },
});
