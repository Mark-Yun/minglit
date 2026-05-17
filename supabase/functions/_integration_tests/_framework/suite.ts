// _framework/suite.ts — local Supabase 연결 + ctx 생성

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { createActor, type Actor } from "./actor.ts";

export interface Ctx {
  readonly url: string;
  readonly anonKey: string;
  readonly db: SupabaseClient;        // service role — RLS 우회 (assertion + seed 용)
  readonly actAs: {
    user(usernameOrId: string): Promise<Actor>;
    partner(partnerNameOrId: string): Promise<Actor>;
  };
}

let _ctx: Ctx | null = null;

/**
 * suite("category/feature") — 파일 단위 setup.
 * 첫 호출 시 env 에서 SUPABASE_URL / SERVICE_ROLE_KEY / ANON_KEY 캡처.
 * 같은 process 안에서 동일 ctx 재사용 (테스트 간 client 재생성 비용 회피).
 */
export function suite(_featureKey: string): Ctx {
  if (_ctx) return _ctx;

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!url || !serviceKey || !anonKey) {
    throw new Error(
      "suite() requires SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY env vars. " +
        "Run `supabase start` and export from `supabase status -o env`.",
    );
  }

  const db = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  _ctx = {
    url,
    anonKey,
    db,
    actAs: {
      user: (id) => createActor("user", id, url, anonKey, db),
      partner: (id) => createActor("partner", id, url, anonKey, db),
    },
  };

  return _ctx;
}
