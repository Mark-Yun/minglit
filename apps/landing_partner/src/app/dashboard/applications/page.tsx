import { Suspense } from "react";

import { PartnerApplicationsPage } from "@/components/partner-operations-console";

export const metadata = {
  title: "신청 관리 | Minglit Partner",
};

export default function PartnerApplicationsRoute() {
  return (
    <Suspense fallback={null}>
      <PartnerApplicationsPage />
    </Suspense>
  );
}
