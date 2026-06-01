// core/snapshot.ts — WorldSnapshot 빌더
//
// 실 운영: 단일 RPC sim_snapshot(actor_ids) 로 1 RT 채우는 게 이상 (architecture.md
// Part 2.A — World Snapshot). PoC 단계: 다중 select 로 빌드 (RPC 신설은 후속 작업).
// dev/rc soak 에서는 실제 feed 대상 전체를 관찰한다. 격리는 workflow target
// environment 로 맡긴다.

import type { SupabaseClient } from "@supabase/supabase-js";
import type { WorldSnapshot } from "./observable.ts";

export async function buildSnapshot(
  supabase: SupabaseClient,
): Promise<WorldSnapshot> {
  const { data: partyRows } = await supabase
    .from("parties")
    .select("id, partner_id, status");
  const parties = (partyRows ?? []) as Array<{
    id: string;
    partner_id: string;
    status: string;
  }>;
  const partyIds = parties.map((p) => p.id);

  if (partyIds.length === 0) {
    return emptySnapshot();
  }

  const { data: eventRows } = await supabase
    .from("events")
    .select("id, party_id, status, start_time")
    .in("party_id", partyIds);
  const events = (eventRows ?? []) as Array<{
    id: string;
    party_id: string;
    status: string;
    start_time: string;
  }>;
  const eventIds = events.map((e) => e.id);
  const partnerIds = parties.map((p) => p.partner_id);

  const [ticketRows, appRows, partRows, voteRows, blockRows] = await Promise
    .all(
      [
        eventIds.length > 0
          ? supabase.from("tickets").select("id, event_id, price").in(
            "event_id",
            eventIds,
          )
          : Promise.resolve({ data: [] }),
        eventIds.length > 0
          ? supabase
            .from("event_applications")
            .select("id, user_id, event_id, status")
            .in("event_id", eventIds)
          : Promise.resolve({ data: [] }),
        eventIds.length > 0
          ? supabase
            .from("event_participants")
            .select("id, user_id, event_id, status")
            .in("event_id", eventIds)
          : Promise.resolve({ data: [] }),
        eventIds.length > 0
          ? supabase
            .from("match_votes")
            .select("event_id, voter_id, candidate_id")
            .in("event_id", eventIds)
          : Promise.resolve({ data: [] }),
        supabase
          .from("social_interactions")
          .select("user_id, target_id, target_type")
          .eq("interaction_type", "block")
          .eq("target_type", "partner")
          .in("target_id", partnerIds),
      ],
    );

  const tickets = (ticketRows.data ?? []) as Array<
    { id: string; event_id: string; price: number }
  >;

  // tickets 를 event 에 attach (observable 모델이 event.tickets 기대)
  const ticketsByEvent = new Map<
    string,
    Array<{ id: string; price: number }>
  >();
  for (const t of tickets) {
    if (!ticketsByEvent.has(t.event_id)) ticketsByEvent.set(t.event_id, []);
    ticketsByEvent.get(t.event_id)!.push({ id: t.id, price: t.price });
  }
  const eventsWithTickets = events.map((e) => ({
    ...e,
    tickets: ticketsByEvent.get(e.id) ?? [],
  }));

  return {
    parties,
    events: eventsWithTickets,
    applications: ((appRows.data ?? []) as Array<{
      id: string;
      user_id: string;
      event_id: string;
      status: string;
    }>),
    participants: ((partRows.data ?? []) as Array<{
      id: string;
      user_id: string;
      event_id: string;
      status: string;
    }>),
    votes: ((voteRows.data ?? []) as Array<{
      event_id: string;
      voter_id: string;
      candidate_id: string;
    }>),
    blocks: ((blockRows.data ?? []) as Array<{
      user_id: string;
      target_id: string;
      target_type: string;
    }>),
  };
}

export function emptySnapshot(): WorldSnapshot {
  return {
    parties: [],
    events: [],
    applications: [],
    participants: [],
    votes: [],
    blocks: [],
  };
}
