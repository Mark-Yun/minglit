// _framework/actor.ts — JWT 발급 + EF invoke

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export interface Actor {
  readonly id: string;
  readonly role: "user" | "partner";
  /** EF 호출 — JWT 자동 부착. status + parsed json 반환 */
  invoke(efName: string, body: unknown): Promise<{ status: number; data: unknown }>;
}

// token cache: cacheKey → JWT (suite 수명 동안 재사용)
const _tokenCache = new Map<string, string>();

/**
 * Actor 생성. 식별자는 username 또는 user_profiles.id 중 하나:
 * - 36자 UUID 형식이면 id 로 간주, auth.admin.getUserById 로 email 조회
 * - 그 외는 username 으로 간주, user_profiles → auth.users 매핑
 *
 * 비밀번호는 SIM_USER_PASSWORD env (기본 'password1234!') 사용.
 */
export async function createActor(
  role: "user" | "partner",
  identifier: string,
  url: string,
  anonKey: string,
  db: SupabaseClient,
): Promise<Actor> {
  const cacheKey = `${role}:${identifier}`;
  let token = _tokenCache.get(cacheKey);

  if (!token) {
    const password = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
    const email = await resolveEmail(role, identifier, db);

    const client = createClient(url, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await client.auth.signInWithPassword({ email, password });
    if (error || !data.session?.access_token) {
      throw new Error(`actor signIn failed for ${cacheKey} (${email}): ${error?.message ?? "no session"}`);
    }
    token = data.session.access_token;
    _tokenCache.set(cacheKey, token);
  }

  const id = await resolveId(role, identifier, db);

  return {
    id,
    role,
    async invoke(efName, body) {
      const res = await fetch(`${url}/functions/v1/${efName}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${token}`,
        },
        body: JSON.stringify(body),
      });
      const data = await res.json().catch(() => null);
      return { status: res.status, data };
    },
  };
}

async function resolveEmail(
  role: "user" | "partner",
  identifier: string,
  db: SupabaseClient,
): Promise<string> {
  // UUID v4 모양이면 id 로 간주
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(identifier)) {
    const { data, error } = await db.auth.admin.getUserById(identifier);
    if (error || !data?.user?.email) {
      throw new Error(`resolveEmail: cannot find ${role} by id=${identifier}: ${error?.message ?? "no user"}`);
    }
    return data.user.email;
  }

  // 그 외는 username 으로 간주 — user_profiles 또는 partner_members 경유
  if (role === "user") {
    const { data: profile, error } = await db
      .from("user_profiles")
      .select("id")
      .eq("username", identifier)
      .maybeSingle();
    if (error || !profile) {
      throw new Error(`resolveEmail user: profile not found for username=${identifier}`);
    }
    const { data: auth } = await db.auth.admin.getUserById(profile.id as string);
    if (!auth?.user?.email) throw new Error(`resolveEmail user: auth.users missing for ${identifier}`);
    return auth.user.email;
  }

  // partner: identifier = partner_id, 첫 멤버 email 사용
  const { data: members, error } = await db
    .from("partner_members")
    .select("user_id")
    .eq("partner_id", identifier)
    .limit(1);
  if (error || !members || members.length === 0) {
    throw new Error(`resolveEmail partner: no member for partner_id=${identifier}`);
  }
  const { data: auth } = await db.auth.admin.getUserById((members[0] as { user_id: string }).user_id);
  if (!auth?.user?.email) throw new Error(`resolveEmail partner: auth.users missing for ${identifier}`);
  return auth.user.email;
}

async function resolveId(
  role: "user" | "partner",
  identifier: string,
  db: SupabaseClient,
): Promise<string> {
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(identifier)) {
    return identifier;
  }
  if (role === "user") {
    const { data } = await db.from("user_profiles").select("id").eq("username", identifier).single();
    return (data as { id: string }).id;
  }
  return identifier; // partner — identifier 가 partner_id
}

/** 테스트 간 token 캐시 정리 (필요 시) */
export function clearTokenCache(): void {
  _tokenCache.clear();
}
