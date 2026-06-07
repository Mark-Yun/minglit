import type { Metadata } from "next";
import { PartnerDashboardPage } from "@/components/partner-console";

export const metadata: Metadata = {
  title: "파트너 대시보드 | 밍글릿 파트너",
  description: "Minglit 파트너 콘솔 홈",
};

export default function DashboardRoute() {
  return <PartnerDashboardPage />;
}
