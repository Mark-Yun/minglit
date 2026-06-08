import type { SupabaseClient } from "@supabase/supabase-js";
import { createBrowserClient } from "@minglit/web-kit/supabase";

let browserClient: SupabaseClient | null | undefined;

export function getSupabaseBrowserClient(): SupabaseClient | null {
  if (browserClient !== undefined) return browserClient;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  // web-kit createBrowserClient() throws on missing env; preserve the existing
  // null-on-missing-config contract (callers map null → "config-error").
  if (!url || !publishableKey) {
    browserClient = null;
    return browserClient;
  }

  // web-kit's client is typed against @supabase/ssr's bundled supabase-js
  // version; bridge to this app's SupabaseClient type (same runtime client).
  browserClient = createBrowserClient() as unknown as SupabaseClient;

  return browserClient;
}
