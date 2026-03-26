/**
 * Environment variable validation based on env-manifest.json.
 *
 * Provides per-function and whole-project env checks so missing keys are
 * caught early (at request time or via the health endpoint).
 */

import manifest from "../../env-manifest.json" with { type: "json" };

type ManifestSection = Record<string, { desc: string }>;

interface FunctionEntry {
  required?: ManifestSection;
  optional?: ManifestSection;
}

/** Return names of *required* env vars that are missing for `functionName`. */
export function validateEnv(functionName: string): string[] {
  const commonRequired: ManifestSection =
    (manifest.edge_functions as { common: { required: ManifestSection } }).common.required ?? {};
  const fnEntry: FunctionEntry =
    ((manifest.edge_functions as { functions: Record<string, FunctionEntry> }).functions)[functionName] ?? {};
  const fnRequired: ManifestSection = fnEntry.required ?? {};
  const allRequired = { ...commonRequired, ...fnRequired };

  return Object.keys(allRequired).filter((k) => !Deno.env.get(k));
}

/**
 * Guard helper — call at the top of any Edge Function handler.
 *
 * Returns a 500 `Response` when required env vars are missing, or `null` when
 * everything is present.
 *
 * ```ts
 * const envErr = requireEnv("notification-worker");
 * if (envErr) return envErr;
 * ```
 */
export function requireEnv(functionName: string): Response | null {
  const missing = validateEnv(functionName);
  if (missing.length > 0) {
    return new Response(
      JSON.stringify({ error: `Missing env: ${missing.join(", ")}` }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
  return null;
}

/**
 * Check every function listed in the manifest and return a map of
 * `functionName -> missingKeys[]` (only functions with gaps are included).
 */
export function checkAllFunctions(): Record<string, string[]> {
  const result: Record<string, string[]> = {};
  const functions = (manifest.edge_functions as { functions: Record<string, FunctionEntry> }).functions;
  for (const fn of Object.keys(functions)) {
    const missing = validateEnv(fn);
    if (missing.length > 0) result[fn] = missing;
  }
  return result;
}
