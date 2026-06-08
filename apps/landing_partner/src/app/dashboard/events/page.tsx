import type { Metadata } from "next";

import { PartnerEventsHubPage } from "@/components/partner-events-console";

export const metadata: Metadata = {
  title: "파티·이벤트 | 밍글릿 파트너",
  description: "Minglit 파트너 파티와 이벤트 운영 허브",
};

export default function PartnerEventsRoute() {
  return <PartnerEventsHubPage />;
}
