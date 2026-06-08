import type { z } from "zod";
import { getSupabaseEnv } from "../supabase/env";
import { MinglitError } from "./errors";

/**
 * Bearer 토큰 출처 — `SupabaseClient` 가 구조적으로 만족하는 최소 인터페이스.
 * browser/server/middleware 어느 클라이언트든 그대로 넘기면 된다.
 */
export interface SessionSource {
  auth: {
    getSession(): Promise<{
      data: { session: { access_token: string } | null };
    }>;
  };
}

export interface CallEdgeFunctionOptions<TRes> {
  /** zod 응답 스키마 — 주어지면 런타임 검증 후 타입 안전한 값 반환 */
  schema?: z.ZodType<TRes>;
  /** `Idempotency-Key` 헤더 — manifest 가 요구하는 EF(apply-event)는 wrapper 가 기본 생성 */
  idempotencyKey?: string;
  /** 세션 대신 사용할 토큰 (테스트/특수 케이스) */
  accessToken?: string;
  signal?: AbortSignal;
}

/**
 * typed EF 호출 코어.
 *
 * - 함수명·인증 요구의 SSoT 는 `supabase/functions/auth-manifest.json`.
 * - 세션 access token 을 Bearer 로 자동 첨부 (비로그인 시 anon key — public caller EF 용).
 * - 성공(2xx): body 를 `schema` 로 검증해 반환. 불일치 → `MinglitError(kind: "contract")`.
 * - 실패(non-2xx): 에러 envelope `{ error, details? }` 를 `MinglitError` 로 정규화해 throw.
 */
export async function callEdgeFunction<TReq, TRes = unknown>(
  supabase: SessionSource,
  name: string,
  body: TReq,
  options: CallEdgeFunctionOptions<TRes> = {},
): Promise<TRes> {
  const { url, anonKey } = getSupabaseEnv();

  const token =
    options.accessToken ??
    (await supabase.auth.getSession()).data.session?.access_token ??
    anonKey;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    apikey: anonKey,
    Authorization: `Bearer ${token}`,
  };
  if (options.idempotencyKey) {
    headers["Idempotency-Key"] = options.idempotencyKey;
  }

  let response: Response;
  try {
    response = await fetch(`${url}/functions/v1/${name}`, {
      method: "POST",
      headers,
      body: JSON.stringify(body ?? {}),
      signal: options.signal,
    });
  } catch (cause) {
    throw new MinglitError({
      fn: name,
      kind: "network",
      message: `Network error calling edge function ${name}`,
      cause,
    });
  }

  const payload: unknown = await response.json().catch(() => null);

  if (!response.ok) {
    throw MinglitError.fromResponse(name, response.status, payload);
  }

  if (options.schema) {
    const parsed = options.schema.safeParse(payload);
    if (!parsed.success) {
      throw new MinglitError({
        fn: name,
        kind: "contract",
        message: `Edge function ${name} response does not match schema`,
        status: response.status,
        details: parsed.error.issues,
      });
    }
    return parsed.data;
  }

  return payload as TRes;
}
