import type { Metadata } from "next";

import { PartnerEventFormPage } from "@/components/partner-events-console";

export const metadata: Metadata = {
  title: "새 회차 만들기 | 밍글릿 파트너",
  description: "Minglit 파트너 이벤트 회차 생성",
};

export default function NewEventRoute({ searchParams }: { searchParams: { party?: string } }) {
  return <PartnerEventFormPage mode={{ type: "create", initialPartyId: searchParams.party }} />;
}
