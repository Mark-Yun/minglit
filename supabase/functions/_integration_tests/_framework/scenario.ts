// _framework/scenario.ts — 재사용 seed preset
//
// 각 scenario 는 cujTest 호출 직전에 실행됨.
// "fresh" 외 모든 scenario 는 service role 로 직접 INSERT (RLS 우회).
// 더 복잡한 시나리오는 본 파일에 키 추가.

import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

export type ScenarioFn = (db: SupabaseClient) => Promise<void>;

export const scenarios: Record<string, ScenarioFn> = {
  /** No-op — db reset 만 적용된 상태 그대로 */
  fresh: async () => {},

  /**
   * 1 user 만 생성 (auth.users + user_profiles).
   * EF 호출에 user JWT 가 필요한 read-only 테스트용.
   * username: user_test1
   */
  "single-user": async (db) => {
    const password = Deno.env.get("SIM_USER_PASSWORD") ?? "password1234!";
    const email = "user_test1@example.test";

    // auth.users 생성 (이미 있으면 skip)
    const { data: existing } = await db.auth.admin.listUsers();
    let userId = existing?.users.find((u) => u.email === email)?.id;
    if (!userId) {
      const { data, error } = await db.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { username: "user_test1" },
      });
      if (error) throw new Error(`scenario single-user createUser: ${error.message}`);
      userId = data.user!.id;
    }

    // user_profiles upsert (trigger 가 만들 수도 있지만 안전하게 upsert)
    const { error: profileErr } = await db.from("user_profiles").upsert(
      { id: userId, username: "user_test1" },
      { onConflict: "id" },
    );
    if (profileErr) throw new Error(`scenario single-user profile: ${profileErr.message}`);
  },
};

export function applyScenario(name: string, db: SupabaseClient): Promise<void> {
  const fn = scenarios[name];
  if (!fn) throw new Error(`Unknown scenario: ${name}. Available: ${Object.keys(scenarios).join(", ")}`);
  return fn(db);
}
