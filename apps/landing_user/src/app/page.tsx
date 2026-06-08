import { WebUserHome } from "@/components/web-user";
import { getPublicEvents } from "@/lib/events";

export default async function LandingUserPage() {
  const events = await getPublicEvents();

  return <WebUserHome events={events} />;
}
