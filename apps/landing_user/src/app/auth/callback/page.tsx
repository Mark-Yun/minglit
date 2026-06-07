"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { getSupabaseBrowserClient } from "@/lib/supabase";

export default function AuthCallbackPage() {
  return (
    <Suspense fallback={<CallbackShell message="로그인을 확인하고 있습니다." />}>
      <AuthCallbackContent />
    </Suspense>
  );
}

function AuthCallbackContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = normalizeReturnPath(searchParams.get("next") ?? undefined);
  const [message, setMessage] = useState("로그인을 확인하고 있습니다.");

  useEffect(() => {
    let cancelled = false;

    async function finishLogin() {
      const supabase = getSupabaseBrowserClient();
      if (!supabase) {
        setMessage("Supabase 공개 환경변수가 없어 로그인을 확인할 수 없습니다.");
        return;
      }

      const { error } = await supabase.auth.getSession();
      if (cancelled) return;
      if (error) {
        setMessage(error.message);
        return;
      }

      router.replace(next);
    }

    void finishLogin();

    return () => {
      cancelled = true;
    };
  }, [next, router]);

  return (
    <main className="web-login-intent">
      <section className="web-login-intent__panel" aria-labelledby="callback-title">
        <div className="minglit-logo web-login-intent__logo" aria-hidden="true">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </div>
        <h1 id="callback-title">로그인 처리 중</h1>
        <p>{message}</p>
        <div className="web-login-intent__actions">
          <Link className="web-login-intent__secondary" href={next}>
            이전 화면으로 돌아가기
          </Link>
        </div>
      </section>
    </main>
  );
}

function CallbackShell({ message }: { message: string }) {
  return (
    <main className="web-login-intent">
      <section className="web-login-intent__panel" aria-labelledby="callback-fallback-title">
        <div className="minglit-logo web-login-intent__logo" aria-hidden="true">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </div>
        <h1 id="callback-fallback-title">로그인 처리 중</h1>
        <p>{message}</p>
      </section>
    </main>
  );
}

function normalizeReturnPath(value?: string): string {
  if (!value || !value.startsWith("/") || value.startsWith("//")) return "/";

  return value;
}
