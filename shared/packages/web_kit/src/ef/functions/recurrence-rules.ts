// recurrence-rules — 반복 이벤트 규칙 CRUD (action dispatch)
// manifest: caller=user (파트너 권한은 서버에서 requirePartnerPermission(PARTY_MANAGE) 으로 검사)
// 역산 출처: supabase/functions/recurrence-rules/index.ts + _handlers/{create,update,pause,resume,cancel}.ts
//           + migrations/20260405000002_recurrence_rules.sql
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export type RecurrenceRulesAction =
  | "create"
  | "update"
  | "pause"
  | "resume"
  | "cancel";

/** weekly/biweekly/monthly — VALID_PATTERNS (_lib/types.ts) */
export type RecurrencePattern = "weekly" | "biweekly" | "monthly";

/**
 * 규칙 생성. weekly/biweekly 는 days_of_week(0~6) 필수, monthly 는 month_day(1~31) 필수.
 * start_time/end_time 은 "HH:MM" 포맷. 생성 직후 today→today+30d 이벤트가 자동 생성된다.
 */
export interface RecurrenceCreateRequest {
  action: "create";
  party_id: string;
  pattern: RecurrencePattern;
  /** 0(일)~6(토) */
  days_of_week: number[];
  /** monthly 패턴 필수, 그 외 null 허용 */
  month_day?: number | null;
  /** "HH:MM" */
  start_time: string;
  /** "HH:MM" */
  end_time: string;
  end_date?: string | null;
}

/** 규칙 수정 — 보낸 필드만 부분 갱신. 최소 1개 필드 필요. cancelled 규칙은 수정 불가. */
export interface RecurrenceUpdateRequest {
  action: "update";
  rule_id: string;
  pattern?: RecurrencePattern;
  days_of_week?: number[];
  month_day?: number | null;
  start_time?: string;
  end_time?: string;
  end_date?: string | null;
}

/** 활성 규칙 일시정지 (status active→paused). */
export interface RecurrencePauseRequest {
  action: "pause";
  rule_id: string;
}

/** 일시정지 규칙 재개 (status paused→active) + 누락 이벤트 재생성. */
export interface RecurrenceResumeRequest {
  action: "resume";
  rule_id: string;
}

/** 규칙 취소 (status→cancelled, 비가역). */
export interface RecurrenceCancelRequest {
  action: "cancel";
  rule_id: string;
}

export type RecurrenceRulesRequest =
  | RecurrenceCreateRequest
  | RecurrenceUpdateRequest
  | RecurrencePauseRequest
  | RecurrenceResumeRequest
  | RecurrenceCancelRequest;

export const recurrenceRulesResponseSchema = z.object({
  success: z.literal(true),
  /** action=create 일 때만 */
  rule_id: z.string().optional(),
  /** action=create / resume 일 때 자동 생성된 이벤트 수 */
  events_created: z.number().optional(),
});
export type RecurrenceRulesResponse = z.infer<
  typeof recurrenceRulesResponseSchema
>;

export function recurrenceRules(
  supabase: SessionSource,
  body: RecurrenceRulesRequest,
  options?: { signal?: AbortSignal },
): Promise<RecurrenceRulesResponse> {
  return callEdgeFunction(supabase, "recurrence-rules", body, {
    schema: recurrenceRulesResponseSchema,
    signal: options?.signal,
  });
}
