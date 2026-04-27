import type { Metadata } from "next";
import Sidebar from "@/components/Sidebar";
import "./globals.css";

export const metadata: Metadata = {
  title: "Minglit Design System",
  description: "Design tokens, screen specs, navigation flows, and component reference for the Minglit app.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        <Sidebar />
        <main className="ml-56 min-h-screen p-8 bg-[var(--color-surface)]">
          {children}
        </main>
      </body>
    </html>
  );
}
