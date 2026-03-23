// validation_utils.ts — Shared validation utilities for Edge Functions
// Issue #311: partner-register EF에서 사용하는 검증 유틸

export type ValidationError = {
  field: string;
  message: string;
};

/**
 * Validates that a string field is non-empty.
 */
export function requireNonEmpty(
  value: unknown,
  field: string,
  label: string,
): ValidationError | null {
  if (typeof value !== "string" || value.trim().length === 0) {
    return { field, message: `${label}은(는) 필수 항목입니다` };
  }
  return null;
}

/**
 * Validates biz_type is a valid enum value.
 */
const VALID_BIZ_TYPES = ["individual", "corporate"];

export function validateBizType(value: unknown): ValidationError | null {
  if (typeof value !== "string" || !VALID_BIZ_TYPES.includes(value)) {
    return { field: "biz_type", message: "사업자 유형이 올바르지 않습니다 (individual/corporate)" };
  }
  return null;
}

/**
 * Validates Korean business registration number (10-digit + checksum).
 *
 * Format: 10 consecutive digits.
 * Checksum: weighted sum mod 10 algorithm used by NTS.
 */
export function validateBizNumber(value: unknown): ValidationError | null {
  if (typeof value !== "string") {
    return { field: "biz_number", message: "올바른 사업자번호 형식이 아닙니다" };
  }

  const digits = value.replace(/-/g, "");
  if (!/^\d{10}$/.test(digits)) {
    return { field: "biz_number", message: "올바른 사업자번호 형식이 아닙니다" };
  }

  // NTS checksum weights
  const weights = [1, 3, 7, 1, 3, 7, 1, 3, 5];
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += parseInt(digits[i]) * weights[i];
  }
  sum += Math.floor((parseInt(digits[8]) * 5) / 10);
  const checkDigit = (10 - (sum % 10)) % 10;

  if (checkDigit !== parseInt(digits[9])) {
    return { field: "biz_number", message: "올바른 사업자번호 형식이 아닙니다" };
  }

  return null;
}

/**
 * Validates Korean phone number format: 01X-XXXX-XXXX (digits only).
 */
export function validatePhone(value: unknown): ValidationError | null {
  if (typeof value !== "string" || !/^01[016789]\d{7,8}$/.test(value.replace(/-/g, ""))) {
    return { field: "contact_phone", message: "올바른 전화번호 형식이 아닙니다" };
  }
  return null;
}

/**
 * Validates email format (basic RFC 5322 pattern).
 */
export function validateEmail(value: unknown): ValidationError | null {
  if (typeof value !== "string" || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
    return { field: "contact_email", message: "올바른 이메일 형식이 아닙니다" };
  }
  return null;
}
