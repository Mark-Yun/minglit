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
    tickets: [{
      id: "t1",
      price: 0,
      status: "on_sale",
      quantity: 10,
      sold_count: 0,
    }],
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
      initialSnapshot: emptySnapshot(), // no events → applyAction.canExecute=false
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
  name:
    "runCascade - successful apply consumes local ticket availability within the same tick",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const snap = snapshotWithOneEvent();
    snap.events[0].tickets![0].quantity = 1;
    snap.events[0].tickets![0].sold_count = 0;
    const { transport, calls } = recordingTransport();

    const { finalSnapshot, trace } = await runCascade({
      actors: [
        { id: "user-1", role: "user" },
        { id: "user-2", role: "user" },
      ],
      initialSnapshot: snap,
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 1,
    });

    assertEquals(calls.length, 1);
    assertEquals(calls[0].actorId, "user-1");
    assertEquals(trace.length, 1);
    assertEquals(finalSnapshot.events[0].tickets![0].sold_count, 1);
    assertEquals(finalSnapshot.applications, [
      {
        id: "local:user-1:e1",
        user_id: "user-1",
        event_id: "e1",
        status: "local_applied",
      },
    ]);
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
  name:
    "runCascade - refreshSnapshot callback advances world state between ticks",
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
    assertEquals(
      refreshCalls,
      3,
      "refreshSnapshot must be invoked after each tick",
    );
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

// Fix #2545: throttle 동작 검증 — EF call 사이 delay 보장
Deno.test({
  name: "runCascade - delayBetweenCallsMs throttles between EF calls",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const { transport, calls } = recordingTransport();
    const start = performance.now();
    await runCascade({
      actors: [
        { id: "user-1", role: "user" as const },
        { id: "user-2", role: "user" as const },
        { id: "user-3", role: "user" as const },
      ],
      initialSnapshot: snapshotWithOneEvent(),
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 1,
      delayBetweenCallsMs: 50,
    });
    const elapsed = performance.now() - start;
    // 3 호출 사이 2 delay × 50ms = 100ms 최소 (모든 actor 가 action 발생 시)
    // policy 가 일부 skip 해도 1 call 발생하면 +50ms 보장. 최소 50ms 확인 (느슨한 lower bound).
    assertEquals(calls.length > 0, true, "at least one EF call expected");
    assertEquals(
      elapsed >= 50,
      true,
      `elapsed (${elapsed}ms) should be >= 50ms with throttle`,
    );
  },
});

Deno.test({
  name: "runCascade - delayBetweenCallsMs=0 (default) no throttle",
  fn: async () => {
    clearRegistry();
    registerAction(applyAction);
    const { transport, calls } = recordingTransport();
    const start = performance.now();
    await runCascade({
      actors: [
        { id: "user-1", role: "user" as const },
        { id: "user-2", role: "user" as const },
        { id: "user-3", role: "user" as const },
      ],
      initialSnapshot: snapshotWithOneEvent(),
      rates: defaultRates,
      transport,
      rng: createPRNG(1),
      ticks: 1,
      // delayBetweenCallsMs omitted → undefined → no delay
    });
    const elapsed = performance.now() - start;
    assertEquals(calls.length > 0, true);
    assertEquals(
      elapsed < 50,
      true,
      `elapsed (${elapsed}ms) should be < 50ms without throttle`,
    );
  },
});
