"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { useState } from "react";
import { getSupabaseBrowserClient } from "@/lib/supabase";

type LoginProvider = "google" | "kakao";

const providers: Array<{ id: LoginProvider; label: string }> = [
  { id: "google", label: "Google로 계속" },
  { id: "kakao", label: "Kakao로 계속" },
];

export default function LoginPage() {
  return (
    <Suspense fallback={<LoginShell message="로그인 화면을 준비하고 있습니다." />}>
      <LoginContent />
    </Suspense>
  );
}

function LoginContent() {
  const searchParams = useSearchParams();
  const next = normalizeReturnPath(searchParams.get("next") ?? undefined);
  const [pendingProvider, setPendingProvider] = useState<LoginProvider | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  async function signIn(provider: LoginProvider) {
    const supabase = getSupabaseBrowserClient();
    if (!supabase) {
      setMessage("Supabase 공개 환경변수가 없어 로그인을 시작할 수 없습니다.");
      return;
    }

    setPendingProvider(provider);
    setMessage(null);
    const redirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo },
    });

    if (error) {
      setMessage(error.message);
      setPendingProvider(null);
    }
  }

  return (
    <main className="web-login-intent">
      <section className="web-login-intent__panel" aria-labelledby="login-title">
        <div className="minglit-logo web-login-intent__logo" aria-hidden="true">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </div>
        <h1 id="login-title">로그인이 필요해요</h1>
        <p>신청, 결제, 구매 내역은 로그인 후 이어갈 수 있습니다.</p>
        <div className="web-login-intent__actions">
          {providers.map((provider) => (
            <button
              key={provider.id}
              className="web-login-intent__primary"
              type="button"
              disabled={pendingProvider !== null}
              onClick={() => signIn(provider.id)}
            >
              {pendingProvider === provider.id ? "연결 중..." : provider.label}
            </button>
          ))}
          <Link className="web-login-intent__secondary" href={next}>
            이전 화면으로 돌아가기
          </Link>
        </div>
        {message ? <p className="web-login-intent__error" role="alert">{message}</p> : null}
      </section>
    </main>
  );
}

function LoginShell({ message }: { message: string }) {
  return (
    <main className="web-login-intent">
      <section className="web-login-intent__panel" aria-labelledby="login-fallback-title">
        <div className="minglit-logo web-login-intent__logo" aria-hidden="true">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </div>
        <h1 id="login-fallback-title">로그인이 필요해요</h1>
        <p>{message}</p>
      </section>
    </main>
  );
}

function normalizeReturnPath(value?: string): string {
  if (!value || !value.startsWith("/") || value.startsWith("//")) return "/";

  return value;
}
