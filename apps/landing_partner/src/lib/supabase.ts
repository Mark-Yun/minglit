import type { SupabaseClient } from "@supabase/supabase-js";
import { createBrowserClient } from "@minglit/web-kit/supabase";

let browserClient: SupabaseClient | null | undefined;

export function getSupabaseBrowserClient(): SupabaseClient | null {
  if (browserClient !== undefined) return browserClient;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !publishableKey) {
    browserClient = null;
    return browserClient;
  }

  browserClient = createBrowserClient() as unknown as SupabaseClient;
  return browserClient;
}
