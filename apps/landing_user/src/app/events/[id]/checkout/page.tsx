import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/web-user";
import { WebUserCheckout } from "@/components/web-user-checkout";
import { getPublicEvent } from "@/lib/events";
import { findCheckoutTicket } from "@/lib/user-orders";

type CheckoutPageProps = {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ ticket?: string }>;
};

export async function generateMetadata({ params }: CheckoutPageProps): Promise<Metadata> {
  const { id } = await params;
  const event = await getPublicEvent(id);

  return {
    title: event ? `${event.title} 신청 · 결제 | Minglit` : "신청 · 결제 | Minglit",
  };
}

export default async function CheckoutPage({ params, searchParams }: CheckoutPageProps) {
  const { id } = await params;
  const { ticket: ticketId } = await searchParams;
  const event = await getPublicEvent(id);

  if (!event) {
    return <EmptyState title="이벤트를 찾을 수 없어요" description="주소가 바뀌었거나 공개되지 않은 이벤트입니다." />;
  }

  const ticket = findCheckoutTicket(event, ticketId ?? null);
  if (!ticket) redirect(`/events/${event.id}`);

  return <WebUserCheckout event={event} ticket={ticket} />;
}
