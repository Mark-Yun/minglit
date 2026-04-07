/** 현재 시각을 ISO 8601 문자열로 반환 (DB updated_at용) */
export function nowISO(): string {
  return Temporal.Now.instant().toString();
}

/** ISO 문자열 → Unix epoch (초) 변환 */
export function isoToUnix(iso: string): number {
  return Math.floor(Temporal.Instant.from(iso).epochMilliseconds / 1000);
}

/** 현재 Unix epoch (초) */
export function nowUnix(): number {
  return Math.floor(Temporal.Now.instant().epochMilliseconds / 1000);
}
