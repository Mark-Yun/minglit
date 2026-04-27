import { errorResponse } from "../../_shared/response_utils.ts";
import { VALID_GENDERS } from "./constants.ts";

export function validateEntryGroupTemplates(templates: unknown[]): Response | null {
  for (let i = 0; i < templates.length; i++) {
    const t = templates[i] as Record<string, unknown>;
    if (typeof t !== "object" || t === null || Array.isArray(t)) {
      return errorResponse(
        `entry_group_templates[${i}] must be an object`,
        400,
      );
    }
    // Fix #1733: 새 그룹은 빈 id 또는 미전송 허용 — 기존 그룹만 id 유지
    if (t.id !== undefined && typeof t.id !== "string") {
      return errorResponse(
        `entry_group_templates[${i}].id must be a string when provided`,
        400,
      );
    }
    if (t.gender !== undefined && t.gender !== null) {
      if (typeof t.gender !== "string" || !VALID_GENDERS.includes(t.gender as typeof VALID_GENDERS[number])) {
        return errorResponse(
          `entry_group_templates[${i}].gender must be one of: ${
            VALID_GENDERS.join(", ")
          }`,
          400,
        );
      }
    }
    if (t.birth_year_min !== undefined && t.birth_year_min !== null) {
      if (
        typeof t.birth_year_min !== "number" || t.birth_year_min < 1900 ||
        t.birth_year_min > 2100
      ) {
        return errorResponse(
          `entry_group_templates[${i}].birth_year_min must be a valid year`,
          400,
        );
      }
    }
    if (t.birth_year_max !== undefined && t.birth_year_max !== null) {
      if (
        typeof t.birth_year_max !== "number" || t.birth_year_max < 1900 ||
        t.birth_year_max > 2100
      ) {
        return errorResponse(
          `entry_group_templates[${i}].birth_year_max must be a valid year`,
          400,
        );
      }
    }
    if (
      t.birth_year_min !== undefined && t.birth_year_max !== undefined &&
      t.birth_year_min !== null && t.birth_year_max !== null
    ) {
      if ((t.birth_year_min as number) > (t.birth_year_max as number)) {
        return errorResponse(
          `entry_group_templates[${i}].birth_year_min cannot exceed birth_year_max`,
          400,
        );
      }
    }
  }
  return null;
}

export function validateTicketTemplates(templates: unknown[]): Response | null {
  for (let i = 0; i < templates.length; i++) {
    const t = templates[i] as Record<string, unknown>;
    if (typeof t !== "object" || t === null || Array.isArray(t)) {
      return errorResponse(`ticket_templates[${i}] must be an object`, 400);
    }
    if (typeof t.name !== "string" || !t.name.trim()) {
      return errorResponse(`ticket_templates[${i}].name is required`, 400);
    }
    if (typeof t.quantity !== "number" || t.quantity < 0) {
      return errorResponse(
        `ticket_templates[${i}].quantity must be a non-negative number`,
        400,
      );
    }
    if (t.price !== undefined && t.price !== null) {
      if (typeof t.price !== "number" || t.price < 0) {
        return errorResponse(`ticket_templates[${i}].price must be >= 0`, 400);
      }
    }
  }
  return null;
}
