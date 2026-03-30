import type { Metadata } from "next";
import { StatsigAnalyticsProvider } from "@/components/statsig-provider";
import "./globals.css";

export const metadata: Metadata = {
  title: "밍글릿 파트너",
  description: "신뢰 기반 소셜 이벤트 매칭 플랫폼, 밍글릿 파트너 서비스",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body className="antialiased">
        <StatsigAnalyticsProvider>
          {children}
        </StatsigAnalyticsProvider>
      </body>
    </html>
  );
}
