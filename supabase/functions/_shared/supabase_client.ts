import { createClient, type SupabaseClient } from "@supabase/supabase-js";

function isSecretApiKey(value: string): boolean {
  return value.startsWith("sb_secret_");
}

function parseSecretKeys(raw: string | undefined): string[] {
  if (!raw) return [];

  try {
    const parsed = JSON.parse(raw) as unknown;
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      const record = parsed as Record<string, unknown>;
      const values = Object.values(record).filter((value): value is string =>
        typeof value === "string" && isSecretApiKey(value)
      );
      const defaultKey = record.default;
      if (typeof defaultKey === "string" && isSecretApiKey(defaultKey)) {
        return [defaultKey, ...values.filter((value) => value !== defaultKey)];
      }
      return values;
    }

    if (Array.isArray(parsed)) {
      return parsed.filter((value): value is string =>
        typeof value === "string" && isSecretApiKey(value)
      );
    }
  } catch {
    // Treat malformed runtime secrets as absent; callers fail closed unless a
    // legacy service_role JWT fallback is configured.
  }

  return [];
}

/**
 * Supabase's hosted runtime exposes new secret API keys as the
 * SUPABASE_SECRET_KEYS JSON dictionary. The legacy service_role JWT remains in
 * SUPABASE_SERVICE_ROLE_KEY.
 */
export function getSupabaseSecretApiKeys(): string[] {
  const keys = parseSecretKeys(Deno.env.get("SUPABASE_SECRET_KEYS"));

  // Local compatibility only: some local env files put sb_secret_ directly in
  // SUPABASE_SERVICE_ROLE_KEY. Do not accept it as a bearer JWT, but allow it as
  // an apikey credential.
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (
    serviceRoleKey && isSecretApiKey(serviceRoleKey) &&
    !keys.includes(serviceRoleKey)
  ) {
    return [...keys, serviceRoleKey];
  }

  return keys;
}

export function getLegacyServiceRoleJwt(): string | undefined {
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  return key && !isSecretApiKey(key) ? key : undefined;
}

export function getSupabaseAdminKey(): string | undefined {
  return getSupabaseSecretApiKeys()[0] ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? undefined;
}

export function makeSupabaseAdminHeaders(): Record<string, string> {
  const key = getSupabaseAdminKey();
  if (!key) {
    throw new Error(
      "Missing required environment variables: SUPABASE_URL and either SUPABASE_SECRET_KEYS or SUPABASE_SERVICE_ROLE_KEY",
    );
  }

  const headers: Record<string, string> = { apikey: key };
  if (!isSecretApiKey(key)) {
    headers.Authorization = `Bearer ${key}`;
  }
  return headers;
}

function makeSupabaseAdminFetch(key: string): typeof fetch | undefined {
  if (!isSecretApiKey(key)) return undefined;

  return (input, init) => {
    const requestInit = init as globalThis.RequestInit | undefined;
    const inputRequest = input instanceof Request ? input : undefined;
    const headers = new Headers(requestInit?.headers ?? inputRequest?.headers);
    const defaultSecretBearer = `Bearer ${key}`;
    if (headers.get("Authorization") === defaultSecretBearer) {
      headers.delete("Authorization");
    }
    return fetch(input, { ...requestInit, headers });
  };
}

/**
 * Service-role Supabase client — bypasses RLS.
 * Use only in Edge Functions that need elevated access.
 */
export function createServiceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const key = getSupabaseAdminKey();
  if (!url || !key) {
    throw new Error(
      "Missing required environment variables: SUPABASE_URL and either SUPABASE_SECRET_KEYS or SUPABASE_SERVICE_ROLE_KEY",
    );
  }
  const adminFetch = makeSupabaseAdminFetch(key);
  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    ...(adminFetch ? { global: { fetch: adminFetch } } : {}),
  });
}
