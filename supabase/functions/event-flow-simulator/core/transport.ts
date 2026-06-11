// core/transport.ts — 실 EF 호출 Transport + direct DB write 분기 (block 액션)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Action, ActorId } from "./types.ts";
import type { Transport } from "./cascade.ts";
import { callEdgeFunction } from "./auth.ts";

export interface EFTransportConfig {
  supabase: SupabaseClient;
  supabaseUrl: string;
  /** actorId → JWT 토큰. cascade 실행 전 모든 actor 의 토큰을 미리 채움 */
  tokenByActor: Map<ActorId, string>;
  /** Current simulator run id, used to avoid idempotency-key reuse across runs. */
  runId?: string;
  /** Backoff delays for Supabase Edge Runtime load transients. */
  edgeLoadRetryDelaysMs?: number[];
}

const IDEMPOTENCY_REQUIRED_FUNCTIONS = new Set(["apply-event"]);
const ALREADY_APPLIED_ERROR = "Already applied to this event";
const EDGE_LOAD_FAILURE_ERROR = "Failed to load edge function";
const DEFAULT_EDGE_LOAD_RETRY_DELAYS_MS = [500, 1_500, 3_000];

/**
 * 실 EF 호출 transport. action.ef 가 정의돼 있으면 callEdgeFunction 으로 POST.
 * action.ef 가 undefined 인 경우 (현재: block 액션) supabase client 로 direct DB write.
 */
export class EFTransport implements Transport {
  private idempotencySequence = 0;

  constructor(private cfg: EFTransportConfig) {}

  async execute(action: Action) {
    const token = this.cfg.tokenByActor.get(action.actorId);
    if (!token) {
      return {
        ok: false,
        status: 0,
        error: `no token for actor ${action.actorId}`,
      };
    }

    // direct DB write 분기 (block 액션)
    if (action.type === "user_block") {
      const partyId = action.payload.party_id as string;
      const { data: party } = await this.cfg.supabase
        .from("parties")
        .select("partner_id")
        .eq("id", partyId)
        .maybeSingle();
      if (!party) {
        return { ok: false, status: 404, error: `party ${partyId} not found` };
      }
      const partnerId = (party as { partner_id: string }).partner_id;
      const { error } = await this.cfg.supabase
        .from("social_interactions")
        .upsert({
          user_id: action.actorId,
          target_id: partnerId,
          target_type: "partner",
          interaction_type: "block",
        });
      if (error) {
        return { ok: false, status: 500, error: error.message };
      }
      return { ok: true, status: 200 };
    }

    // 일반 EF 호출
    if (!action.ef) {
      return { ok: false, status: 0, error: `action ${action.type} has no ef` };
    }
    const functionName = action.ef;
    const extraHeaders = this.headersForAction(action);
    const res = await this.callEdgeFunctionWithLoadRetry(
      functionName,
      action.payload,
      token,
      extraHeaders,
    );
    const rawError = extractResponseError(res.data);
    if (isAlreadyAppliedConflict(action, res.status, rawError)) {
      return {
        ok: true,
        status: res.status,
        data: { type: "already_applied" },
      };
    }

    const ok = res.status >= 200 && res.status < 300;
    return {
      ok,
      status: res.status,
      data: res.data,
      error: ok ? undefined : rawError,
    };
  }

  private headersForAction(action: Action): Record<string, string> {
    if (!action.ef || !IDEMPOTENCY_REQUIRED_FUNCTIONS.has(action.ef)) {
      return {};
    }
    const runId = this.cfg.runId ?? "unknown-run";
    const sequence = this.idempotencySequence++;
    return {
      "Idempotency-Key":
        `event-flow-simulator:${runId}:${sequence}:${action.type}`,
    };
  }

  private async callEdgeFunctionWithLoadRetry(
    functionName: string,
    payload: Record<string, unknown>,
    token: string,
    extraHeaders: Record<string, string>,
  ): Promise<{ status: number; data: unknown }> {
    const retryDelays = this.cfg.edgeLoadRetryDelaysMs ??
      DEFAULT_EDGE_LOAD_RETRY_DELAYS_MS;

    for (let attempt = 0;; attempt++) {
      const res = await callEdgeFunction(
        this.cfg.supabaseUrl,
        functionName,
        payload,
        token,
        extraHeaders,
      );
      const rawError = extractResponseError(res.data);
      if (
        !isEdgeLoadFailure(res.status, rawError) ||
        attempt >= retryDelays.length
      ) {
        return res;
      }

      const delayMs = retryDelays[attempt] ?? 0;
      if (delayMs > 0) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }
  }
}

function isAlreadyAppliedConflict(
  action: Action,
  status: number,
  error: string | undefined,
): boolean {
  return action.type === "user_apply" &&
    action.ef === "apply-event" &&
    status === 409 &&
    error === ALREADY_APPLIED_ERROR;
}

function extractResponseError(data: unknown): string | undefined {
  if (typeof data === "string" && data.length > 0) return data;
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return undefined;
  }
  const record = data as Record<string, unknown>;
  const message = record.error ?? record.message;
  return typeof message === "string" && message.length > 0
    ? message
    : undefined;
}

function isEdgeLoadFailure(status: number, error: string | undefined): boolean {
  return status === 503 && error === EDGE_LOAD_FAILURE_ERROR;
}
