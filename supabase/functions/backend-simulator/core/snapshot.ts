// core/snapshot.ts — WorldSnapshot 빌더
//
// 실 운영: 단일 RPC sim_snapshot(actor_ids) 로 1 RT 채우는 게 이상 (architecture.md
// Part 2.A — World Snapshot). PoC 단계: 다중 select 로 빌드 (RPC 신설은 후속 작업).
// [E2E] prefix 가드로 시뮬 데이터만 격리.

import type { SupabaseClient } from "@supabase/supabase-js";
import type { WorldSnapshot } from "./observable.ts";

export async function buildSnapshot(supabase: SupabaseClient): Promise<WorldSnapshot> {
  // [E2E] prefix party 만 시뮬 대상
  const { data: partyRows } = await supabase
    .from("parties")
    .select("id, partner_id, status")
    .like("title", "[E2E]%");
  const parties = (partyRows ?? []) as Array<{
    id: string;
    partner_id: string;
    status: string;
  }>;
  const partyIds = parties.map((p) => p.id);

  if (partyIds.length === 0) {
    return emptySnapshot();
  }

  const [eventRows, ticketRows, appRows, partRows, voteRows, blockRows] = await Promise.all([
    supabase
      .from("events")
      .select("id, party_id, status, start_time")
      .in("party_id", partyIds),
    supabase.from("tickets").select("id, event_id, price"),
    supabase
      .from("event_applications")
      .select("id, user_id, event_id, status"),
    supabase
      .from("event_participants")
      .select("id, user_id, event_id, status"),
    supabase
      .from("match_votes")
      .select("event_id, voter_id, candidate_id"),
    supabase
      .from("social_interactions")
      .select("user_id, target_id, target_type")
      .eq("interaction_type", "block")
      .eq("target_type", "partner"),
  ]);

  const events =
    ((eventRows.data ?? []) as Array<{
      id: string;
      party_id: string;
      status: string;
      start_time: string;
    }>);
  const tickets =
    ((ticketRows.data ?? []) as Array<{ id: string; event_id: string; price: number }>);

  // tickets 를 event 에 attach (observable 모델이 event.tickets 기대)
  const ticketsByEvent = new Map<string, Array<{ id: string; price: number }>>();
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
    applications:
      ((appRows.data ?? []) as Array<{
        id: string;
        user_id: string;
        event_id: string;
        status: string;
      }>),
    participants:
      ((partRows.data ?? []) as Array<{
        id: string;
        user_id: string;
        event_id: string;
        status: string;
      }>),
    votes:
      ((voteRows.data ?? []) as Array<{
        event_id: string;
        voter_id: string;
        candidate_id: string;
      }>),
    blocks:
      ((blockRows.data ?? []) as Array<{
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
