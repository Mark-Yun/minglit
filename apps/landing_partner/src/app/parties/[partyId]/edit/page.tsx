import type { Metadata } from "next";

import { PartnerPartyFormPage } from "@/components/partner-events-console";

export const metadata: Metadata = {
  title: "파티 수정 | 밍글릿 파트너",
  description: "Minglit 파트너 파티 수정",
};

export default function EditPartyRoute({ params }: { params: { partyId: string } }) {
  return <PartnerPartyFormPage mode={{ type: "edit", partyId: params.partyId }} />;
}
