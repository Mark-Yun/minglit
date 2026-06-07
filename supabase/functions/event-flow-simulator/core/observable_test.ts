import { assertEquals } from "@std/assert";
import { projectForPartner, type WorldSnapshot } from "./observable.ts";

Deno.test("projectForPartner scopes events and pending applications to owned parties", () => {
  const snapshot: WorldSnapshot = {
    parties: [
      { id: "party-owned", partner_id: "partner-1", status: "active" },
      { id: "party-other", partner_id: "partner-2", status: "active" },
    ],
    events: [
      {
        id: "event-owned",
        party_id: "party-owned",
        status: "scheduled",
        start_time: "2026-06-07T12:00:00.000Z",
      },
      {
        id: "event-other",
        party_id: "party-other",
        status: "scheduled",
        start_time: "2026-06-07T12:00:00.000Z",
      },
    ],
    applications: [
      {
        id: "app-pending",
        user_id: "user-1",
        event_id: "event-owned",
        status: "pending_review",
      },
      {
        id: "app-approved",
        user_id: "user-2",
        event_id: "event-owned",
        status: "approved",
      },
      {
        id: "app-other",
        user_id: "user-3",
        event_id: "event-other",
        status: "pending_review",
      },
    ],
    participants: [],
    votes: [],
    blocks: [],
  };

  const state = projectForPartner(snapshot, "partner-1");

  assertEquals(state["myParties"], [snapshot.parties[0]]);
  assertEquals(state["myEvents"], [snapshot.events[0]]);
  assertEquals(state["pendingApplications"], [snapshot.applications[0]]);
});
