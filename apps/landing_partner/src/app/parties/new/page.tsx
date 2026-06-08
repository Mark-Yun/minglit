import type { Metadata } from "next";

import { PartnerPartyFormPage } from "@/components/partner-events-console";

export const metadata: Metadata = {
  title: "새 파티 만들기 | 밍글릿 파트너",
  description: "Minglit 파트너 파티 생성",
};

export default function NewPartyRoute() {
  return <PartnerPartyFormPage mode={{ type: "create" }} />;
}
