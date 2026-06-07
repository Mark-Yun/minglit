import type { Metadata } from "next";
import { Suspense } from "react";
import { PartnerLoginPage } from "@/components/partner-console";

export const metadata: Metadata = {
  title: "파트너 로그인 | 밍글릿 파트너",
  description: "Minglit 파트너 콘솔 OAuth 로그인",
};

export default function LoginRoute() {
  return (
    <Suspense
      fallback={
        <main className="wpl-canvas">
          <section className="wpl-card">로그인 화면을 준비하고 있어요.</section>
        </main>
      }
    >
      <PartnerLoginPage />
    </Suspense>
  );
}
