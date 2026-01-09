import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Minglit | Verified Vibe, Spark Your Moment",
  description: "신뢰와 설렘이 공존하는 검증 기반 블라인드 미팅 서비스, 밍글릿",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
