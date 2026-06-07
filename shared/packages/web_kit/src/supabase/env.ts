import { z } from "zod";

/**
 * Supabase 공개 env — Next.js 클라이언트 번들 인라인을 위해
 * 반드시 `process.env.NEXT_PUBLIC_*` 리터럴 멤버 접근으로 읽는다.
 */
const supabaseEnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z
    .string()
    .min(1, "NEXT_PUBLIC_SUPABASE_URL is required")
    .startsWith("http", "NEXT_PUBLIC_SUPABASE_URL must be a URL"),
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: z
    .string()
    .min(1, "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY is required"),
});

export interface SupabaseEnv {
  url: string;
  anonKey: string;
}

/** env 를 zod 로 검증해 반환. 누락/형식 오류 시 명확한 메시지로 throw. */
export function getSupabaseEnv(): SupabaseEnv {
  const parsed = supabaseEnvSchema.safeParse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  });

  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => issue.message)
      .join("; ");
    throw new Error(`[web-kit] Invalid Supabase env: ${issues}`);
  }

  return {
    url: parsed.data.NEXT_PUBLIC_SUPABASE_URL,
    anonKey: parsed.data.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  };
}
