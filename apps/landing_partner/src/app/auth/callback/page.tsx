"use client";

import { Loader2 } from "lucide-react";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { getSupabaseBrowserClient } from "@/lib/supabase";

export default function AuthCallbackRoute() {
  return (
    <Suspense fallback={<CallbackStatus message="로그인 정보를 확인하고 있어요." />}>
      <AuthCallbackContent />
    </Suspense>
  );
}

function AuthCallbackContent() {
  const router = useRouter();
  const params = useSearchParams();
  const [message, setMessage] = useState("로그인 정보를 확인하고 있어요.");

  useEffect(() => {
    let cancelled = false;

    async function finishAuth() {
      const supabase = getSupabaseBrowserClient();
      const next = sanitizeNext(params.get("next"));

      if (!supabase) {
        setMessage("Supabase 공개 환경변수가 없어 로그인 복귀를 완료할 수 없어요.");
        return;
      }

      const { error } = await supabase.auth.getSession();
      if (cancelled) return;

      if (error) {
        router.replace(`/login?error=${encodeURIComponent(error.message)}&next=${encodeURIComponent(next)}`);
        return;
      }

      router.replace(next);
    }

    void finishAuth();

    return () => {
      cancelled = true;
    };
  }, [params, router]);

  return <CallbackStatus message={message} />;
}

function CallbackStatus({ message }: { message: string }) {
  return (
    <main className="wpl-callback">
      <div className="wpl-callback__card">
        <Loader2 aria-hidden="true" />
        <p>{message}</p>
      </div>
    </main>
  );
}

function sanitizeNext(value: string | null): string {
  if (!value || !value.startsWith("/") || value.startsWith("//")) return "/dashboard";
  return value;
}
