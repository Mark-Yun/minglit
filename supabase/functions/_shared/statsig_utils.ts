/**
 * Statsig REST API utilities for Supabase Edge Functions.
 * Uses REST API directly (no SDK) for Deno compatibility.
 * Gracefully no-ops when STATSIG_SERVER_KEY is not set.
 *
 * Pattern follows logger.ts.
 */

let _enabled = false;
let _apiKey: string | null = null;

const STATSIG_LOG_EVENT_URL = "https://events.statsigapi.net/v1/log_event";
const STATSIG_CHECK_GATE_URL = "https://api.statsig.com/v1/check_gate";
const REQUEST_TIMEOUT_MS = 5000;

/**
 * Initialize Statsig. Call once at module top-level.
 * No-ops if STATSIG_SERVER_KEY env var is missing or empty.
 */
export function initStatsig(apiKey?: string): void {
  const key = apiKey ?? Deno.env.get("STATSIG_SERVER_KEY") ?? "";
  if (!key) {
    _enabled = false;
    return;
  }
  _apiKey = key;
  _enabled = true;
}

/**
 * Log an analytics event to Statsig.
 * No-ops if not initialized.
 */
export async function logStatsigEvent(
  userId: string,
  eventName: string,
  value?: number,
  metadata?: Record<string, string>,
): Promise<void> {
  if (!_enabled || !_apiKey) return;

  const payload = {
    events: [{
      eventName,
      user: { userID: userId },
      ...(value !== undefined && { value }),
      ...(metadata && { metadata }),
    }],
  };

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    const response = await fetch(STATSIG_LOG_EVENT_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "statsig-api-key": _apiKey,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    }).finally(() => clearTimeout(timeoutId));

    // Consume response body to avoid resource leaks
    await response.body?.cancel();
  } catch (_error) {
    // Graceful degradation — never throw from analytics
  }
}

/**
 * Check a feature gate in Statsig.
 * Returns false if not initialized or on failure.
 */
export async function checkStatsigGate(
  userId: string,
  gateName: string,
): Promise<boolean> {
  if (!_enabled || !_apiKey) return false;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    const response = await fetch(STATSIG_CHECK_GATE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "statsig-api-key": _apiKey,
      },
      body: JSON.stringify({
        user: { userID: userId },
        gateName,
      }),
      signal: controller.signal,
    }).finally(() => clearTimeout(timeoutId));

    if (!response.ok) {
      await response.body?.cancel();
      return false;
    }

    const data = await response.json();
    return data.value === true;
  } catch (_error) {
    return false;
  }
}

/** Reset internal state. For testing only. */
export function _resetStatsigForTesting(): void {
  _enabled = false;
  _apiKey = null;
}
