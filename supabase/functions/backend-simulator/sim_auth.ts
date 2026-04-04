// sim_auth.ts — Auth helper for backend-simulator: user JWT acquisition + EF calls

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

// Token cache: email → JWT access_token (valid for the duration of a single run)
const _tokenCache = new Map<string, string>();

/**
 * Sign in a seed user via email/password and return the JWT access_token.
 * Uses a per-run in-memory cache to avoid redundant signIn calls.
 *
 * Seed user password is read from env SIM_USER_PASSWORD (default: 'password1234!').
 */
export async function getSimUserToken(
  supabaseUrl: string,
  anonKey: string,
  email: string,
  password: string,
): Promise<string> {
  const cached = _tokenCache.get(email);
  if (cached) return cached;

  const supabase = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
  });

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error || !data.session?.access_token) {
    throw new Error(`getSimUserToken: failed to sign in ${email}: ${error?.message ?? "no session"}`);
  }

  const token = data.session.access_token;
  _tokenCache.set(email, token);
  return token;
}

/**
 * HTTP POST to a Supabase Edge Function with a Bearer token.
 * Returns { status, data }.
 */
export async function callEdgeFunction(
  supabaseUrl: string,
  functionName: string,
  payload: unknown,
  userToken: string,
): Promise<{ status: number; data: unknown }> {
  const url = `${supabaseUrl}/functions/v1/${functionName}`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${userToken}`,
    },
    body: JSON.stringify(payload),
  });

  let data: unknown;
  try {
    data = await res.json();
  } catch {
    data = null;
  }

  return { status: res.status, data };
}

/**
 * Clear the token cache. Useful between test runs.
 */
export function clearTokenCache(): void {
  _tokenCache.clear();
}

/**
 * Sign in a partner seed user via email/password and return the JWT access_token.
 * Uses a per-run in-memory cache with a `partner_` prefix to avoid key collision
 * with user tokens from getSimUserToken.
 */
export async function getSimPartnerToken(
  supabaseUrl: string,
  anonKey: string,
  partnerEmail: string,
  password: string,
): Promise<string> {
  const cacheKey = `partner_${partnerEmail}`;
  const cached = _tokenCache.get(cacheKey);
  if (cached) return cached;

  const supabase = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
  });

  const { data, error } = await supabase.auth.signInWithPassword({ email: partnerEmail, password });
  if (error || !data.session?.access_token) {
    throw new Error(`getSimPartnerToken: failed to sign in ${partnerEmail}: ${error?.message ?? "no session"}`);
  }

  const token = data.session.access_token;
  _tokenCache.set(cacheKey, token);
  return token;
}

/**
 * Look up the email address for a partner's member account.
 * Queries partner_members to find a member for the given partner_id,
 * then fetches the auth user record to retrieve their email.
 * Returns null if no member or auth user is found.
 */
export async function getPartnerEmail(
  supabase: SupabaseClient,
  partnerId: string,
): Promise<string | null> {
  const { data: members, error: memberErr } = await supabase
    .from("partner_members")
    .select("user_id")
    .eq("partner_id", partnerId)
    .limit(1);

  if (memberErr || !members || members.length === 0) return null;

  const userId = (members[0] as { user_id: string }).user_id;
  const { data: authUser, error: authErr } = await supabase.auth.admin.getUserById(userId);
  if (authErr || !authUser?.user?.email) return null;

  return authUser.user.email;
}
