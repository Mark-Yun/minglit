import type { Metadata } from "next";

import { PartnerEventFormPage } from "@/components/partner-events-console";
import { shouldOpenCancelDialog } from "@/lib/partner-events";

export const metadata: Metadata = {
  title: "이벤트 수정 | 밍글릿 파트너",
  description: "Minglit 파트너 이벤트 회차 수정",
};

export default function EditEventRoute({
  params,
  searchParams,
}: {
  params: { eventId: string };
  searchParams: { cancel?: string | string[] };
}) {
  return (
    <PartnerEventFormPage
      mode={{
        type: "edit",
        eventId: params.eventId,
        initialShowCancel: shouldOpenCancelDialog(searchParams.cancel),
      }}
    />
  );
}
