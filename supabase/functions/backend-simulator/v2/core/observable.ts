// v2/core/observable.ts — World snapshot + role-based observable projections

/**
 * WorldSnapshot = 시뮬레이션의 "현재 진실".
 * 실 운영에선 cascade 시작 시 단일 RPC 호출로 채워짐 (Part 2.A — World Snapshot).
 * PoC 단계에선 테스트가 직접 fixture 만듦.
 */
export interface WorldSnapshot {
  parties: Array<{ id: string; partner_id: string; status: string }>;
  events: Array<{
    id: string;
    party_id: string;
    status: string;
    start_time: string;
    tickets?: Array<{ id: string; price: number }>;
  }>;
  applications: Array<{
    id: string;
    user_id: string;
    event_id: string;
    status: string;
  }>;
  participants: Array<{
    id: string;
    user_id: string;
    event_id: string;
    status: string;
  }>;
  votes: Array<{
    event_id: string;
    voter_id: string;
    candidate_id: string;
  }>;
  blocks: Array<{
    user_id: string;
    target_id: string;
    target_type: string;
  }>;
}

/**
 * ObservableState = 특정 actor 가 자신의 API 호출로 "볼 수 있는" 상태.
 * RLS 와 등가 — service role 우회 금지. 시뮬레이터가 잘못된 정보로 결정하면 실 유저
 * 행동과 발산함.
 */
export interface ObservableState {
  [key: string]: unknown;
}

export function projectForUser(snapshot: WorldSnapshot, userId: string): ObservableState {
  return {
    myApplications: snapshot.applications.filter((a) => a.user_id === userId),
    visibleEvents: snapshot.events.filter((e) =>
      e.status === "scheduled" || e.status === "active"
    ),
    myParticipations: snapshot.participants.filter((p) => p.user_id === userId),
    myVotes: snapshot.votes.filter((v) => v.voter_id === userId),
    myBlocks: snapshot.blocks.filter((b) => b.user_id === userId),
  };
}

export function projectForPartner(snapshot: WorldSnapshot, partnerId: string): ObservableState {
  const myPartyIds = snapshot.parties
    .filter((p) => p.partner_id === partnerId)
    .map((p) => p.id);
  const myEventIds = snapshot.events
    .filter((e) => myPartyIds.includes(e.party_id))
    .map((e) => e.id);
  return {
    myParties: snapshot.parties.filter((p) => p.partner_id === partnerId),
    myEvents: snapshot.events.filter((e) => myPartyIds.includes(e.party_id)),
    pendingApplications: snapshot.applications.filter(
      (a) => myEventIds.includes(a.event_id) && a.status === "pending_review",
    ),
  };
}
