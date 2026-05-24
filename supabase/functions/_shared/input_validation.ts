import { errorResponse } from "./response_utils.ts";

export type InputResult<T> = T | Response;

export const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isPlainRecord(
  value: unknown,
): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function requireStringField(
  body: Record<string, unknown>,
  field: string,
  message = `Missing required field: ${field}`,
): InputResult<string> {
  const value = body[field];
  if (typeof value !== "string" || value.length === 0) {
    return errorResponse(message, 400);
  }
  return value;
}

export function optionalStringField(
  body: Record<string, unknown>,
  field: string,
  message = `Invalid field: ${field}`,
): InputResult<string | undefined> {
  const value = body[field];
  if (value === undefined) return undefined;
  if (typeof value !== "string") return errorResponse(message, 400);
  return value;
}

export function requireUuidField(
  body: Record<string, unknown>,
  field: string,
  messages: { missing: string; invalid: string },
): InputResult<string> {
  const value = requireStringField(body, field, messages.missing);
  if (value instanceof Response) return value;
  if (!UUID_RE.test(value)) return errorResponse(messages.invalid, 400);
  return value;
}
