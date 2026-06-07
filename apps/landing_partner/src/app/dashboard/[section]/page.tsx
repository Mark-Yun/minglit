import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { PartnerDashboardSectionPage } from "@/components/partner-console";
import { dashboardSections, getPartnerDashboardSection } from "@/lib/partner-dashboard";

export const metadata: Metadata = {
  title: "파트너 콘솔 | 밍글릿 파트너",
  description: "Minglit 파트너 콘솔 섹션",
};

export function generateStaticParams() {
  return dashboardSections
    .filter((section) => section.key !== "events")
    .map((section) => ({ section: section.key }));
}

export default function DashboardSectionRoute({ params }: { params: { section: string } }) {
  const section = getPartnerDashboardSection(params.section);
  if (!section) notFound();

  return <PartnerDashboardSectionPage section={section} />;
}
