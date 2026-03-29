/**
 * PII (Personally Identifiable Information) masking utility.
 *
 * 개인정보보호법 제29조 안전조치의무 준수를 위해
 * 로그 전송 전 개인정보 필드를 마스킹한다.
 *
 * 대상 필드: name, phone, birth_date, ci, di, email, address,
 *           phoneNumber, birthDate, phone_number 등.
 */

/** PII로 간주하는 필드명 (소문자 비교) */
const PII_FIELD_NAMES = new Set([
  "name",
  "phone",
  "phone_number",
  "phonenumber",
  "birth_date",
  "birthdate",
  "ci",
  "di",
  "email",
  "address",
]);

/**
 * Fix #763: Sentry 구조적 부모 키 — 이 키 아래의 "name" 등 PII 필드는
 * exception type name, sdk name 등 구조적 데이터이므로 마스킹하지 않는다.
 */
const SENTRY_STRUCTURAL_PARENTS = new Set([
  "exception",
  "mechanism",
  "stacktrace",
  "breadcrumbs",
  "debug_meta",
  "frames",
  "values",
]);

/** 최대 재귀 깊이 — 순환 참조 방지 */
const MAX_DEPTH = 10;

/**
 * 문자열 값을 마스킹한다.
 * - 1글자: "*"
 * - 2글자: 첫 글자 + "*"
 * - 3글자 이상: 첫 글자 + "***" + 마지막 글자
 * - 전화번호 패턴 (010-1234-5678): 중간 번호를 ****로 대체
 */
export function maskValue(value: string): string {
  if (value.length === 0) return value;

  // 전화번호 패턴: 010-1234-5678 또는 01012345678
  const phoneWithDash = /^(\d{2,3})-(\d{3,4})-(\d{4})$/;
  const phoneNoDash = /^(01[016789])(\d{3,4})(\d{4})$/;

  const dashMatch = value.match(phoneWithDash);
  if (dashMatch) {
    return `${dashMatch[1]}-****-${dashMatch[3]}`;
  }
  const noDashMatch = value.match(phoneNoDash);
  if (noDashMatch) {
    return `${noDashMatch[1]}****${noDashMatch[3]}`;
  }

  // 이메일 패턴
  const emailMatch = value.match(/^(.)[^@]*(@.+)$/);
  if (emailMatch) {
    return `${emailMatch[1]}***${emailMatch[2]}`;
  }

  // 일반 문자열
  if (value.length === 1) return "*";
  if (value.length === 2) return value[0] + "*";
  return value[0] + "*".repeat(Math.min(value.length - 2, 3)) + value[value.length - 1];
}

/**
 * 값이 PII 필드인지 판단하여 마스킹한다.
 * ci/di는 긴 해시이므로 앞 8자만 남기고 나머지는 마스킹한다.
 */
function maskPiiValue(fieldName: string, value: unknown): unknown {
  if (typeof value !== "string" || value.length === 0) return value;

  const lower = fieldName.toLowerCase();
  if (lower === "ci" || lower === "di") {
    // ci/di: 앞 8자 + "..."
    return value.length > 8 ? value.slice(0, 8) + "..." : maskValue(value);
  }

  return maskValue(value);
}

/**
 * 객체를 재귀적으로 순회하며 PII 필드를 마스킹한 새 객체를 반환한다.
 * 원본 객체는 변경하지 않는다 (immutable).
 *
 * @param parentKey - 부모 객체에서 이 obj를 가리키는 키 (Sentry 구조적 키 판별용)
 */
export function maskPii(obj: unknown, depth = 0, parentKey?: string): unknown {
  // Fix #763: depth limit 도달 시 원본 반환 — 문자열 반환 시 Sentry beforeSend 등 호출자 타입 깨짐
  if (depth > MAX_DEPTH) return obj;

  if (obj === null || obj === undefined) return obj;
  if (typeof obj === "string") return obj;
  if (typeof obj === "number" || typeof obj === "boolean") return obj;

  if (Array.isArray(obj)) {
    return obj.map((item) => maskPii(item, depth + 1, parentKey));
  }

  if (typeof obj === "object") {
    const result: Record<string, unknown> = {};
    // Fix #763: Sentry 구조적 부모 키 아래에서는 PII 필드 마스킹 스킵
    const isSentryStructural = parentKey !== undefined &&
      SENTRY_STRUCTURAL_PARENTS.has(parentKey.toLowerCase());
    for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
      const lowerKey = key.toLowerCase();
      if (PII_FIELD_NAMES.has(lowerKey) && !isSentryStructural) {
        result[key] = maskPiiValue(key, value);
      } else if (typeof value === "object" && value !== null) {
        result[key] = maskPii(value, depth + 1, key);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  return obj;
}

/**
 * JSON 문자열 내 PII를 마스킹한다.
 * Portone 등 외부 API 에러 메시지가 JSON.stringify된 경우 파싱 후 마스킹.
 * 파싱 실패 시 PII 유출 방지를 위해 fallback 메시지를 반환한다.
 */
export function maskJsonString(
  str: string,
  fallback = "[masked: unparseable error]",
): string {
  try {
    const parsed = JSON.parse(str);
    if (typeof parsed === "object" && parsed !== null) {
      return JSON.stringify(maskPii(parsed));
    }
  } catch {
    // JSON 파싱 실패 — PII 포함 가능성이 있으므로 fallback 반환
  }
  return fallback;
}

/**
 * Record<string, unknown> 형태의 metadata를 마스킹한다.
 * axiom_logger / logger에서 사용.
 */
export function maskMetadata(
  metadata: Record<string, unknown> | undefined,
): Record<string, unknown> | undefined {
  if (!metadata) return metadata;
  return maskPii(metadata) as Record<string, unknown>;
}
