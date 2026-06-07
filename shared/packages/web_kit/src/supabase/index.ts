// @minglit/web-kit/supabase — 클라이언트 팩토리 (browser / server / middleware)
// 기준: docs/architecture/web-client.md §2.1, §3 (@supabase/ssr 쿠키 세션)
export { createBrowserClient } from "./browser";
export { createServerClient, type ServerCookieStore } from "./server";
export {
  updateSession,
  applySessionCookies,
  type UpdateSessionResult,
} from "./middleware";
export { getSupabaseEnv, type SupabaseEnv } from "./env";
