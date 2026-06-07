import type { Metadata } from "next";
import { EmptyState, WebUserEventDetail } from "@/components/web-user";
import { getPublicEvent } from "@/lib/events";

type EventDetailPageProps = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: EventDetailPageProps): Promise<Metadata> {
  const { id } = await params;
  const event = await getPublicEvent(id);

  if (!event) {
    return {
      title: "이벤트를 찾을 수 없어요 | Minglit",
    };
  }

  return {
    title: `${event.title} | Minglit`,
    description: event.description,
    openGraph: {
      title: event.title,
      description: event.description,
      images: event.imageUrl ? [{ url: event.imageUrl }] : [],
    },
  };
}

export default async function EventDetailPage({ params }: EventDetailPageProps) {
  const { id } = await params;
  const event = await getPublicEvent(id);

  if (!event) {
    return (
      <EmptyState
        title="이벤트를 찾을 수 없어요"
        description="주소가 바뀌었거나 공개되지 않은 이벤트입니다."
      />
    );
  }

  return <WebUserEventDetail event={event} />;
}
