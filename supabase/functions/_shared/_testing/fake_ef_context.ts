// _shared/_testing/fake_ef_context.ts — EFContext factory for handler unit tests

import type { SupabaseClient } from "@supabase/supabase-js";
import type { AuthContext, EFContext, Environment } from "../edge_function.ts";
import type { FakeSupabase } from "./fake_supabase.ts";

export interface MakeCtxOptions {
  supabase: FakeSupabase | SupabaseClient;
  /** Default auth: user with userId "u-test". Override for system/external/public. */
  auth?: AuthContext;
  /** Convenience: shorthand for { type: "user", userId } */
  userId?: string;
  fnName?: string;
  env?: Environment;
  requestId?: string;
}

export function makeCtx(opts: MakeCtxOptions): EFContext {
  const auth: AuthContext = opts.auth ??
    (opts.userId ? { type: "user", userId: opts.userId } : { type: "user", userId: "u-test" });
  return {
    auth,
    fnName: opts.fnName ?? "test-ef",
    env: opts.env ?? "local",
    requestId: opts.requestId ?? "req-test",
    supabase: opts.supabase as SupabaseClient,
  };
}
