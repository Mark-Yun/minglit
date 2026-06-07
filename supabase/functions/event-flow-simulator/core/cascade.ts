// v2/core/cascade.ts — Stochastic Cascade 엔진

import type { Action, Actor, PRNG } from "./types.ts";
import {
  projectForPartner,
  projectForUser,
  type WorldSnapshot,
} from "./observable.ts";
import type { Trace, TraceEntry } from "./trace.ts";
import { userPolicy } from "../policy/user.ts";
import { partnerPolicy } from "../policy/partner.ts";
import type { Rates } from "../params/default.ts";

/**
 * Transport = action → 실 EF 호출 (또는 mock).
 * 단위 테스트는 in-memory mock 으로 격리.
 */
export interface Transport {
  execute(action: Action): Promise<{
    ok: boolean;
    status: number;
    data?: unknown;
    error?: string;
  }>;
}

export interface CascadeConfig {
  actors: Actor[];
  initialSnapshot: WorldSnapshot;
  rates: Rates;
  transport: Transport;
  rng: PRNG;
  /** 시뮬할 tick 수 */
  ticks: number;
  /** 각 tick 후 snapshot 갱신 콜백 (실 운영: 재조회 RPC). 미제공 시 snapshot 변경 X */
  refreshSnapshot?: (
    current: WorldSnapshot,
    trace: Trace,
  ) => Promise<WorldSnapshot> | WorldSnapshot;
  /** EF 호출 후 throttle delay (ms). Supabase 의 per-trace rate limit (Fix #2545) 회피용. 기본 0 = 즉시. 실 운영 권장 200~400ms */
  delayBetweenCallsMs?: number;
}

export interface CascadeResult {
  trace: Trace;
  finalSnapshot: WorldSnapshot;
}

export async function runCascade(
  config: CascadeConfig,
): Promise<CascadeResult> {
  const trace: Trace = [];
  let snapshot = config.initialSnapshot;

  for (let tick = 0; tick < config.ticks; tick++) {
    for (const actor of config.actors) {
      const observable = actor.role === "user"
        ? projectForUser(snapshot, actor.id)
        : projectForPartner(snapshot, actor.id);

      const policy = actor.role === "user" ? userPolicy : partnerPolicy;
      const actorRng = config.rng.split();
      const action = policy(actor.id, observable, config.rates, actorRng);
      if (!action) continue;

      const result = await config.transport.execute(action);
      const entry: TraceEntry = {
        tick,
        actorId: actor.id,
        action,
        status: result.status,
        ok: result.ok,
      };
      if (result.error) entry.error = result.error;
      trace.push(entry);

      if (result.ok) {
        snapshot = applySuccessfulActionToSnapshot(
          snapshot,
          action,
          result.data,
        );
      }

      // Fix #2545: Supabase per-trace rate limit 회피. EF 호출 후만 sleep (skip-action 시는 즉시 다음).
      if (config.delayBetweenCallsMs && config.delayBetweenCallsMs > 0) {
        await new Promise((r) => setTimeout(r, config.delayBetweenCallsMs));
      }
    }

    if (config.refreshSnapshot) {
      snapshot = await config.refreshSnapshot(snapshot, trace);
    }
  }

  return { trace, finalSnapshot: snapshot };
}

function applySuccessfulActionToSnapshot(
  snapshot: WorldSnapshot,
  action: Action,
  responseData: unknown,
): WorldSnapshot {
  if (action.type !== "user_apply") return snapshot;

  const eventId = action.payload.event_id;
  const ticketId = action.payload.ticket_id;
  if (typeof eventId !== "string" || typeof ticketId !== "string") {
    return snapshot;
  }

  const targetTicket = snapshot.events
    .find((event) => event.id === eventId)
    ?.tickets?.find((ticket) => ticket.id === ticketId);
  const shouldReserveCapacity = shouldReserveApplyTicketCapacity(
    targetTicket?.price,
    responseData,
  );

  const events = shouldReserveCapacity
    ? snapshot.events.map((event) => {
      if (event.id !== eventId || !event.tickets) return event;
      return {
        ...event,
        current_participants: Math.min(
          event.max_participants,
          event.current_participants + 1,
        ),
        tickets: event.tickets.map((ticket) =>
          ticket.id === ticketId
            ? {
              ...ticket,
              sold_count: Math.min(ticket.quantity, ticket.sold_count + 1),
            }
            : ticket
        ),
      };
    })
    : snapshot.events;

  const applications =
    snapshot.applications.some((application) =>
        application.user_id === action.actorId &&
        application.event_id === eventId
      )
      ? snapshot.applications
      : [
        ...snapshot.applications,
        {
          id: `local:${action.actorId}:${eventId}`,
          user_id: action.actorId,
          event_id: eventId,
          status: "local_applied",
        },
      ];

  return { ...snapshot, events, applications };
}

function shouldReserveApplyTicketCapacity(
  ticketPrice: number | undefined,
  responseData: unknown,
): boolean {
  const responseType = applyResponseType(responseData);
  if (responseType === "free") return true;
  if (responseType === "paid") return false;
  return ticketPrice === 0;
}

function applyResponseType(responseData: unknown): string | null {
  if (
    typeof responseData !== "object" ||
    responseData === null ||
    Array.isArray(responseData)
  ) {
    return null;
  }

  const type = (responseData as { type?: unknown }).type;
  return typeof type === "string" ? type : null;
}
