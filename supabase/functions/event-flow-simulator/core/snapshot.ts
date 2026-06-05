// core/snapshot.ts — WorldSnapshot 빌더
//
// 실 운영: 단일 RPC sim_snapshot(actor_ids) 로 1 RT 채우는 게 이상 (architecture.md
// Part 2.A — World Snapshot). PoC 단계: 다중 select 로 빌드 (RPC 신설은 후속 작업).
// dev/rc soak 에서는 실제 feed 대상 전체를 관찰한다. 격리는 workflow target
// environment 로 맡긴다.

import type { SupabaseClient } from "@supabase/supabase-js";
import type { WorldSnapshot } from "./observable.ts";

const PAGE_SIZE = 1000;
const IN_CHUNK_SIZE = 200;

type SelectError = { message?: string } | null;
type SelectResult<T> = { data: T[] | null; error: SelectError };
type SelectBuilder<T> = {
  eq: (column: string, value: unknown) => SelectBuilder<T>;
  in: (column: string, values: unknown[]) => SelectBuilder<T>;
  range: (from: number, to: number) => PromiseLike<SelectResult<T>>;
};

type PartyRow = {
  id: string;
  partner_id: string;
  status: string;
};

type EventRow = {
  id: string;
  party_id: string;
  status: string;
  start_time: string;
};

type TicketRow = {
  id: string;
  event_id: string;
  price: number;
};

type ApplicationRow = {
  id: string;
  user_id: string;
  event_id: string;
  status: string;
};

type ParticipantRow = {
  id: string;
  user_id: string;
  event_id: string;
  status: string;
};

type VoteRow = {
  event_id: string;
  voter_id: string;
  candidate_id: string;
};

type BlockRow = {
  user_id: string;
  target_id: string;
  target_type: string;
};

export async function buildSnapshot(
  supabase: SupabaseClient,
): Promise<WorldSnapshot> {
  const parties = await selectAllRows<PartyRow>(
    supabase,
    "parties",
    "id, partner_id, status",
  );
  const partyIds = parties.map((p) => p.id);

  if (partyIds.length === 0) {
    return emptySnapshot();
  }

  const partyIdSet = new Set(partyIds);
  const events = (await selectAllRows<EventRow>(
    supabase,
    "events",
    "id, party_id, status, start_time",
  )).filter((e) => partyIdSet.has(e.party_id));
  const eventIds = events.map((e) => e.id);
  const partnerIds = uniqueStrings(parties.map((p) => p.partner_id));

  const [tickets, applications, participants, votes, blocks] = await Promise
    .all(
      [
        eventIds.length > 0
          ? selectByInChunks<TicketRow>(
            supabase,
            "tickets",
            "id, event_id, price",
            "event_id",
            eventIds,
          )
          : Promise.resolve([]),
        eventIds.length > 0
          ? selectByInChunks<ApplicationRow>(
            supabase,
            "event_applications",
            "id, user_id, event_id, status",
            "event_id",
            eventIds,
          )
          : Promise.resolve([]),
        eventIds.length > 0
          ? selectByInChunks<ParticipantRow>(
            supabase,
            "event_participants",
            "id, user_id, event_id, status",
            "event_id",
            eventIds,
          )
          : Promise.resolve([]),
        eventIds.length > 0
          ? selectByInChunks<VoteRow>(
            supabase,
            "match_votes",
            "event_id, voter_id, candidate_id",
            "event_id",
            eventIds,
          )
          : Promise.resolve([]),
        partnerIds.length > 0
          ? selectByInChunks<BlockRow>(
            supabase,
            "social_interactions",
            "user_id, target_id, target_type",
            "target_id",
            partnerIds,
            (query) =>
              query.eq("interaction_type", "block").eq(
                "target_type",
                "partner",
              ),
          )
          : Promise.resolve([]),
      ],
    );

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
    applications,
    participants,
    votes,
    blocks,
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

function selectBuilder<T>(
  supabase: SupabaseClient,
  table: string,
  columns: string,
): SelectBuilder<T> {
  return supabase.from(table).select(columns) as unknown as SelectBuilder<T>;
}

async function selectAllRows<T>(
  supabase: SupabaseClient,
  table: string,
  columns: string,
): Promise<T[]> {
  return await selectPaged(
    table,
    () => selectBuilder<T>(supabase, table, columns),
  );
}

async function selectByInChunks<T>(
  supabase: SupabaseClient,
  table: string,
  columns: string,
  column: string,
  values: string[],
  filter?: (query: SelectBuilder<T>) => SelectBuilder<T>,
): Promise<T[]> {
  const rows: T[] = [];
  for (const valueChunk of chunks(uniqueStrings(values), IN_CHUNK_SIZE)) {
    const chunkRows = await selectPaged(table, () => {
      const query = selectBuilder<T>(supabase, table, columns);
      return (filter ? filter(query) : query).in(column, valueChunk);
    });
    rows.push(...chunkRows);
  }
  return rows;
}

async function selectPaged<T>(
  table: string,
  queryFactory: () => SelectBuilder<T>,
): Promise<T[]> {
  const rows: T[] = [];
  for (let from = 0; true; from += PAGE_SIZE) {
    const to = from + PAGE_SIZE - 1;
    const { data, error } = await queryFactory().range(from, to);
    if (error) {
      const message = error.message ?? String(error);
      throw new Error(`buildSnapshot: failed to load ${table}: ${message}`);
    }
    const page = data ?? [];
    rows.push(...page);
    if (page.length < PAGE_SIZE) break;
  }
  return rows;
}

function chunks<T>(values: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < values.length; i += size) {
    result.push(values.slice(i, i + size));
  }
  return result;
}

function uniqueStrings(values: string[]): string[] {
  return [...new Set(values)];
}
