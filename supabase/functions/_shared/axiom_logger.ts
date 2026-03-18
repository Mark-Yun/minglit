/**
 * Axiom structured logging for Edge Functions.
 *
 * Environments: local → console only, development/production → console + Axiom.
 * Gracefully no-ops when AXIOM_API_TOKEN is not set.
 */

export type LogLevel = "debug" | "info" | "warn" | "error";

export interface LogEntry {
  function: string;
  level: LogLevel;
  message: string;
  metadata?: Record<string, unknown>;
}

interface AxiomEvent {
  _time: string;
  function: string;
  level: LogLevel;
  environment: string;
  message: string;
  metadata?: Record<string, unknown>;
}

const _token = Deno.env.get("AXIOM_API_TOKEN") ?? "";
const _dataset = Deno.env.get("AXIOM_DATASET") ?? "edge-functions";
const _environment = Deno.env.get("ENVIRONMENT") ?? "local";
const _enabled = _token.length > 0 && _environment !== "local";

const _buffer: AxiomEvent[] = [];
const MAX_BUFFER_SIZE = 1000;

export function log(entry: LogEntry): void {
  const event: AxiomEvent = {
    _time: new Date().toISOString(),
    function: entry.function,
    level: entry.level,
    environment: _environment,
    message: entry.message,
    ...(entry.metadata && { metadata: entry.metadata }),
  };

  const prefix = `[${entry.function}]`;
  switch (entry.level) {
    case "error":
      console.error(prefix, entry.message, entry.metadata ?? "");
      break;
    case "warn":
      console.warn(prefix, entry.message, entry.metadata ?? "");
      break;
    case "debug":
      console.debug(prefix, entry.message, entry.metadata ?? "");
      break;
    default:
      console.log(prefix, entry.message, entry.metadata ?? "");
  }

  if (_enabled) {
    _buffer.push(event);
    if (_buffer.length > MAX_BUFFER_SIZE) {
      _buffer.shift();
    }
  }
}

function _restoreBuffer(events: AxiomEvent[]): void {
  _buffer.unshift(...events);
  if (_buffer.length > MAX_BUFFER_SIZE) {
    _buffer.splice(MAX_BUFFER_SIZE);
  }
}

export async function flush(): Promise<void> {
  if (!_enabled || _buffer.length === 0) return;

  const events = _buffer.splice(0);
  try {
    const res = await fetch(
      `https://api.axiom.co/v1/datasets/${_dataset}/ingest`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${_token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(events),
        signal: AbortSignal.timeout(5000),
      },
    );
    if (!res.ok) {
      await res.body?.cancel();
      _restoreBuffer(events);
      console.warn(`[axiom_logger] Ingest failed: ${res.status} ${res.statusText}`);
    }
  } catch (e) {
    _restoreBuffer(events);
    console.warn("[axiom_logger] Ingest error:", e);
  }
}

export function extractFunctionName(req: Request): string {
  try {
    const url = new URL(req.url);
    const segments = url.pathname.split("/").filter(Boolean);
    const v1Index = segments.indexOf("v1");
    if (v1Index >= 0 && segments[v1Index + 1]) {
      return segments[v1Index + 1];
    }
    return segments[segments.length - 1] ?? "unknown";
  } catch {
    return "unknown";
  }
}

export function isEnabled(): boolean {
  return _enabled;
}

export function _resetForTesting(): void {
  _buffer.length = 0;
}

export function _getBuffer(): readonly AxiomEvent[] {
  return _buffer;
}
