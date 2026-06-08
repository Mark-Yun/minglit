/**
 * EF 에러 정규화 — `MinglitError` 단일 타입.
 *
 * EF 에러 envelope (supabase/functions/_shared/response_utils.ts 의 errorResponse):
 * ```json
 * { "error": "<메시지 또는 머신 코드>", "details": <unknown, optional> }
 * ```
 * - HTTP status 가 의미를 나르고, `error` 문자열은 사람용 메시지이거나
 *   머신 코드("already_refunded", "refund_not_eligible" 등)일 수 있다.
 * - 일부 EF 는 `details.code` 로 머신 코드를 별도 전달 (예: user-create-order).
 * - rate limit(429) 은 `details.retry_after_seconds` 를 포함.
 */

export type MinglitErrorKind =
  /** 401/403 — 미로그인, 권한 없음 */
  | "auth"
  /** 400/422 — 요청 형식/필드 오류 */
  | "validation"
  /** 404 — 대상 없음 */
  | "not_found"
  /** 409 — 상태 충돌 (중복 신청, 마감 등) */
  | "conflict"
  /** 429 — rate limit */
  | "rate_limit"
  /** 5xx — 서버 오류 */
  | "server"
  /** fetch 실패 — 네트워크/CORS */
  | "network"
  /** 2xx 인데 응답이 zod 스키마와 불일치 — EF 계약 위반 */
  | "contract";

export interface MinglitErrorEnvelope {
  error: string;
  details?: unknown;
}

function kindFromStatus(status: number): MinglitErrorKind {
  if (status === 401 || status === 403) return "auth";
  if (status === 404) return "not_found";
  if (status === 409) return "conflict";
  if (status === 429) return "rate_limit";
  if (status >= 500) return "server";
  return "validation";
}

function isEnvelope(body: unknown): body is MinglitErrorEnvelope {
  return (
    typeof body === "object" &&
    body !== null &&
    typeof (body as { error?: unknown }).error === "string"
  );
}

export class MinglitError extends Error {
  override readonly name = "MinglitError";
  /** 호출한 EF 함수명 */
  readonly fn: string;
  readonly kind: MinglitErrorKind;
  /** HTTP status (network/contract 는 0) */
  readonly status: number;
  /** 머신 코드 — `details.code` 가 있으면 그 값, 없으면 undefined */
  readonly code: string | undefined;
  /** envelope 의 details 원본 */
  readonly details: unknown;
  /** 429 일 때 재시도 대기 초 (`details.retry_after_seconds`) */
  readonly retryAfterSeconds: number | undefined;

  constructor(args: {
    fn: string;
    kind: MinglitErrorKind;
    message: string;
    status?: number;
    code?: string;
    details?: unknown;
    cause?: unknown;
  }) {
    super(args.message, { cause: args.cause });
    this.fn = args.fn;
    this.kind = args.kind;
    this.status = args.status ?? 0;
    this.code = args.code;
    this.details = args.details;

    const details = args.details as
      | { retry_after_seconds?: unknown }
      | undefined
      | null;
    this.retryAfterSeconds =
      typeof details?.retry_after_seconds === "number"
        ? details.retry_after_seconds
        : undefined;
  }

  /** non-2xx 응답 body(파싱된 JSON 또는 null)에서 MinglitError 생성. */
  static fromResponse(fn: string, status: number, body: unknown): MinglitError {
    const envelope = isEnvelope(body) ? body : undefined;
    const details = envelope?.details;
    const code =
      typeof (details as { code?: unknown } | undefined)?.code === "string"
        ? ((details as { code: string }).code)
        : undefined;
    return new MinglitError({
      fn,
      kind: kindFromStatus(status),
      message: envelope?.error ?? `Edge function ${fn} failed (${status})`,
      status,
      code,
      details,
    });
  }
}
