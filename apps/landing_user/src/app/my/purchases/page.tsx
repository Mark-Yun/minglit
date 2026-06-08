import type { Metadata } from "next";
import { WebUserPurchases } from "@/components/web-user-purchases";

type PurchasesPageProps = {
  searchParams: Promise<{ purchase?: string }>;
};

export const metadata: Metadata = {
  title: "구매 내역 | Minglit",
};

export default async function PurchasesPage({ searchParams }: PurchasesPageProps) {
  const { purchase } = await searchParams;

  return <WebUserPurchases selectedId={purchase} />;
}
