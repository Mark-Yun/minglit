/**
 * KST 날짜/시간 포맷터 — 서버(UTC)·브라우저 어디서 렌더해도 항상 Asia/Seoul 기준.
 * date-fns v4 + @date-fns/tz (date-fns 공식 타임존 패키지, KST 는 DST 없음).
 */
import { TZDate } from "@date-fns/tz";
import { differenceInCalendarDays, format } from "date-fns";
import { ko } from "date-fns/locale";

const KST_TIME_ZONE = "Asia/Seoul";

export type DateInput = Date | string | number;

function toKst(input: DateInput): TZDate {
  return new TZDate(new Date(input).getTime(), KST_TIME_ZONE);
}

/** 임의 패턴 KST 포맷 (date-fns 패턴, ko locale) */
export function formatKst(input: DateInput, pattern: string): string {
  return format(toKst(input), pattern, { locale: ko });
}

/** 이벤트 일시 — "6월 12일 (금) 19:30" */
export function formatEventDateTime(input: DateInput): string {
  return formatKst(input, "M월 d일 (EEE) HH:mm");
}

/** 날짜만 — "6월 12일 (금)" */
export function formatEventDate(input: DateInput): string {
  return formatKst(input, "M월 d일 (EEE)");
}

/**
 * D-day — KST 달력일 기준.
 * 오늘 → "오늘" · 미래 → "D-N" · 과거 → "D+N"
 * (spec: web_partner_applications 디데이 칩 — 오늘: warning / D-N: primary)
 */
export function formatDday(target: DateInput, base: DateInput = new Date()): string {
  const days = differenceInCalendarDays(toKst(target), toKst(base));
  if (days === 0) return "오늘";
  return days > 0 ? `D-${days}` : `D+${Math.abs(days)}`;
}

/**
 * 상대시간 — "방금 전" / "N분 전" / "N시간 전" / "N일 전",
 * 7일 이상 과거(또는 미래 시각)는 절대 날짜("M월 d일")로 폴백.
 */
export function formatRelativeTime(
  target: DateInput,
  base: DateInput = new Date(),
): string {
  const diffMs = new Date(base).getTime() - new Date(target).getTime();
  if (diffMs < 0) return formatEventDate(target);

  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 1) return "방금 전";
  if (minutes < 60) return `${minutes}분 전`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}시간 전`;

  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}일 전`;

  return formatEventDate(target);
}
