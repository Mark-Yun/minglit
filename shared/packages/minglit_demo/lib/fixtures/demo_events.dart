/// Event-domain fixtures: `Event`, `EventApplication`, `EventParticipant`,
/// `TodayActiveEvent`.
///
/// Owned by **P1-2 agent**. See task #12.
///
/// Required exports:
///   - `List<Event> demoEvents` — at least 8-10 events with varied state
///     (upcoming, ongoing, past, fully booked, low capacity)
///   - `List<EventApplication> demoEventApplications` — the demo user's
///     submitted applications, in various states (pending/approved/rejected)
///   - `List<EventParticipant> demoEventParticipants` — for "내 참가 중" lists
///   - `List<TodayActiveEvent> demoTodayActiveEvents` — home banner data
///
/// Constraints:
///   - FK: each Event's `partner_id` matches an entry in demo_parties.dart
///   - Times: use `demoWorld.now` as reference for relative timestamps
///   - Cross-app: app_user shows event from consumer angle, app_partner from
///     organizer angle — same Event records
library;

import 'package:minglit_kit/minglit_data.dart';

import 'demo_world.dart';
import 'demo_parties.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

DateTime _t(Duration d) => DemoWorld.offset(d);

// ── Events ─────────────────────────────────────────────────────────────────

/// 8-10 events with varied state: upcoming (several), ongoing (1), past (2),
/// fully booked (1), low capacity (1). Events 1-3 belong to selfPartner;
/// events 4-7 belong to partner2-5.
final List<Event> demoEvents = [
  // ── selfPartner events ──────────────────────────────────────────────────

  // Event 1: upcoming, normal capacity, tagged 음악·대화
  Event(
    id: DemoWorld.selfEvent1Id,
    partyId: DemoWorld.selfParty1Id,
    startTime: _t(const Duration(days: 5, hours: 19)),
    endTime: _t(const Duration(days: 5, hours: 22)),
    createdAt: _t(const Duration(days: -14)),
    updatedAt: _t(const Duration(days: -14)),
    title: '강남 와인 & 재즈 나잇',
    description: {
      'ops': [
        {'insert': '좋은 와인과 라이브 재즈로 가득한 저녁. 새로운 사람들과 여유롭게 대화해보세요.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event1/800/400'],
    maxParticipants: 30,
    currentParticipants: 18,
    remainingSlots: 12,
    status: 'scheduled',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '음악'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.selfParty1Id),
  ),

  // Event 2: upcoming soon (2 days), low capacity — only 3 slots left
  Event(
    id: DemoWorld.selfEvent2Id,
    partyId: DemoWorld.selfParty1Id,
    startTime: _t(const Duration(days: 2, hours: 20)),
    endTime: _t(const Duration(days: 2, hours: 23)),
    createdAt: _t(const Duration(days: -7)),
    updatedAt: _t(const Duration(days: -7)),
    title: '강남 싱글즈 칵테일 파티',
    description: {
      'ops': [
        {'insert': '분위기 있는 바에서 칵테일 한 잔. 자리가 거의 다 찼어요!\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event2/800/400'],
    maxParticipants: 20,
    currentParticipants: 17,
    remainingSlots: 3,
    status: 'scheduled',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '술'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.selfParty1Id),
  ),

  // Event 3: upcoming (10 days), selfParty2 — fully booked
  Event(
    id: DemoWorld.selfEvent3Id,
    partyId: DemoWorld.selfParty2Id,
    startTime: _t(const Duration(days: 10, hours: 14)),
    endTime: _t(const Duration(days: 10, hours: 17)),
    createdAt: _t(const Duration(days: -10)),
    updatedAt: _t(const Duration(days: -3)),
    title: '이태원 보드게임 나잇 — 마감',
    description: {
      'ops': [
        {'insert': '인기 보드게임으로 즐기는 오후. 인원이 꽉 찼습니다!\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event3/800/400'],
    maxParticipants: 24,
    currentParticipants: 24,
    remainingSlots: 0,
    status: 'scheduled',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '게임'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.selfParty2Id),
  ),

  // ── partner2 event ──────────────────────────────────────────────────────

  // Event 4: ongoing right now
  Event(
    id: DemoWorld.partner2EventId,
    partyId: DemoWorld.partner2PartyId,
    startTime: _t(const Duration(hours: -1)),
    endTime: _t(const Duration(hours: 2)),
    createdAt: _t(const Duration(days: -5)),
    updatedAt: _t(const Duration(days: -1)),
    title: '홍대 영화 토크 클럽',
    description: {
      'ops': [
        {'insert': '이번 달 추천 영화를 함께 보고 이야기 나누는 소모임.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event4/800/400'],
    maxParticipants: 16,
    currentParticipants: 12,
    remainingSlots: 4,
    status: 'ongoing',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '영화'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.partner2PartyId),
  ),

  // ── partner3 event ──────────────────────────────────────────────────────

  // Event 5: upcoming (7 days), 예술 themed
  Event(
    id: DemoWorld.partner3EventId,
    partyId: DemoWorld.partner3PartyId,
    startTime: _t(const Duration(days: 7, hours: 18)),
    endTime: _t(const Duration(days: 7, hours: 21)),
    createdAt: _t(const Duration(days: -6)),
    updatedAt: _t(const Duration(days: -6)),
    title: '성수 아트 드로잉 파티',
    description: {
      'ops': [
        {'insert': '캔버스 앞에서 새 친구를 만들어보세요. 그림 실력 무관!\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event5/800/400'],
    maxParticipants: 20,
    currentParticipants: 8,
    remainingSlots: 12,
    status: 'scheduled',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '예술'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.partner3PartyId),
  ),

  // ── partner4 event ──────────────────────────────────────────────────────

  // Event 6: upcoming (14 days), 운동 themed
  Event(
    id: DemoWorld.partner4EventId,
    partyId: DemoWorld.partner4PartyId,
    startTime: _t(const Duration(days: 14, hours: 10)),
    endTime: _t(const Duration(days: 14, hours: 12)),
    createdAt: _t(const Duration(days: -8)),
    updatedAt: _t(const Duration(days: -8)),
    title: '한강 러닝 크루 모임',
    description: {
      'ops': [
        {'insert': '한강 공원을 함께 달리며 에너지 충전! 5km 코스, 초보 환영.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event6/800/400'],
    maxParticipants: 40,
    currentParticipants: 22,
    remainingSlots: 18,
    status: 'scheduled',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '운동'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.partner4PartyId),
  ),

  // ── partner5 event ──────────────────────────────────────────────────────

  // Event 7: upcoming (3 days), 음식 themed
  Event(
    id: DemoWorld.partner5EventId,
    partyId: DemoWorld.partner5PartyId,
    startTime: _t(const Duration(days: 3, hours: 12)),
    endTime: _t(const Duration(days: 3, hours: 15)),
    createdAt: _t(const Duration(days: -4)),
    updatedAt: _t(const Duration(days: -4)),
    title: '망원 브런치 소셜 클럽',
    description: {
      'ops': [
        {'insert': '여유로운 주말 브런치. 맛있는 음식과 좋은 대화가 있는 곳.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event7/800/400'],
    maxParticipants: 25,
    currentParticipants: 10,
    remainingSlots: 15,
    status: 'scheduled',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '음식'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.partner5PartyId),
  ),

  // ── Past events (for history / "내 참가" screens) ────────────────────────

  // Event 8: past (3 days ago), completed — demoUser attended
  Event(
    id: '00000000-0000-4000-8000-300000000008',
    partyId: DemoWorld.selfParty2Id,
    startTime: _t(const Duration(days: -3, hours: 18)),
    endTime: _t(const Duration(days: -3, hours: 21)),
    createdAt: _t(const Duration(days: -20)),
    updatedAt: _t(const Duration(days: -3)),
    title: '이태원 보드게임 나잇 — 5월 편',
    description: {
      'ops': [
        {'insert': '지난 회차 보드게임 파티 아카이브.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event8/800/400'],
    maxParticipants: 24,
    currentParticipants: 24,
    remainingSlots: 0,
    status: 'completed',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '게임'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.selfParty2Id),
  ),

  // Event 9: past (10 days ago), completed — demoUser applied but rejected
  Event(
    id: '00000000-0000-4000-8000-300000000009',
    partyId: DemoWorld.partner3PartyId,
    startTime: _t(const Duration(days: -10, hours: 19)),
    endTime: _t(const Duration(days: -10, hours: 22)),
    createdAt: _t(const Duration(days: -25)),
    updatedAt: _t(const Duration(days: -10)),
    title: '성수 아트 나잇 — 4월 편',
    description: {
      'ops': [
        {'insert': '지난 아트 파티 아카이브.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/event9/800/400'],
    maxParticipants: 20,
    currentParticipants: 19,
    remainingSlots: 0,
    status: 'completed',
    visibility: 'public',
    tags: [
      demoTags.firstWhere((t) => t.name == '예술'),
    ],
    party: demoParties.firstWhere((p) => p.id == DemoWorld.partner3PartyId),
  ),
];

// ── Event Applications ──────────────────────────────────────────────────────

/// Demo user's applications in various states.
final List<EventApplication> demoEventApplications = [
  // Application for event2 (upcoming, approved — demoUser has a ticket)
  EventApplication(
    id: '00000000-0000-4000-8000-500000000001',
    eventId: DemoWorld.selfEvent2Id,
    ticketId: DemoWorld.ticket1Id,
    userId: DemoWorld.userId,
    status: 'approved',
    createdAt: _t(const Duration(days: -6)),
    updatedAt: _t(const Duration(days: -5)),
    paidAt: _t(const Duration(days: -6)),
    paymentAmount: 15000,
  ),

  // Application for event4 (ongoing, approved — demoUser is in it right now)
  EventApplication(
    id: '00000000-0000-4000-8000-500000000002',
    eventId: DemoWorld.partner2EventId,
    ticketId: DemoWorld.ticket2Id,
    userId: DemoWorld.userId,
    status: 'approved',
    createdAt: _t(const Duration(days: -4)),
    updatedAt: _t(const Duration(days: -3)),
    paidAt: _t(const Duration(days: -4)),
    paymentAmount: 0,
  ),

  // Application for event7 (upcoming, pending review)
  EventApplication(
    id: '00000000-0000-4000-8000-500000000003',
    eventId: DemoWorld.partner5EventId,
    ticketId: DemoWorld.ticket3Id,
    userId: DemoWorld.userId,
    status: 'pending',
    createdAt: _t(const Duration(days: -2)),
    updatedAt: _t(const Duration(days: -2)),
  ),

  // Application for event8 (past, attended)
  EventApplication(
    id: '00000000-0000-4000-8000-500000000004',
    eventId: '00000000-0000-4000-8000-300000000008',
    ticketId: '00000000-0000-4000-8000-400000000004',
    userId: DemoWorld.userId,
    status: 'paid',
    createdAt: _t(const Duration(days: -18)),
    updatedAt: _t(const Duration(days: -3)),
    paidAt: _t(const Duration(days: -18)),
    paymentAmount: 12000,
  ),

  // Application for event9 (past, rejected)
  EventApplication(
    id: '00000000-0000-4000-8000-500000000005',
    eventId: '00000000-0000-4000-8000-300000000009',
    ticketId: '00000000-0000-4000-8000-400000000005',
    userId: DemoWorld.userId,
    status: 'rejected',
    createdAt: _t(const Duration(days: -24)),
    updatedAt: _t(const Duration(days: -23)),
    rejectionReason: '해당 이벤트의 조건에 맞지 않습니다.',
  ),
];

// ── Event Participants ──────────────────────────────────────────────────────

/// Confirmed participant records for the demo user.
final List<EventParticipant> demoEventParticipants = [
  // Participant for event2 (upcoming, ticket_issued)
  EventParticipant(
    id: '00000000-0000-4000-8000-600000000001',
    eventId: DemoWorld.selfEvent2Id,
    ticketId: DemoWorld.ticket1Id,
    userId: DemoWorld.userId,
    createdAt: _t(const Duration(days: -5)),
    updatedAt: _t(const Duration(days: -5)),
    applicationId: '00000000-0000-4000-8000-500000000001',
    status: 'ticket_issued',
    ticketCode: 'DEMO-EVT2-0001',
  ),

  // Participant for event4 (ongoing, checked_in)
  EventParticipant(
    id: '00000000-0000-4000-8000-600000000002',
    eventId: DemoWorld.partner2EventId,
    ticketId: DemoWorld.ticket2Id,
    userId: DemoWorld.userId,
    createdAt: _t(const Duration(days: -3)),
    updatedAt: _t(const Duration(hours: -1)),
    applicationId: '00000000-0000-4000-8000-500000000002',
    status: 'checked_in',
    ticketCode: 'DEMO-EVT4-0001',
  ),

  // Participant for event8 (past, ticket_issued — attended)
  EventParticipant(
    id: '00000000-0000-4000-8000-600000000003',
    eventId: '00000000-0000-4000-8000-300000000008',
    ticketId: '00000000-0000-4000-8000-400000000004',
    userId: DemoWorld.userId,
    createdAt: _t(const Duration(days: -3)),
    updatedAt: _t(const Duration(days: -3)),
    applicationId: '00000000-0000-4000-8000-500000000004',
    status: 'ticket_issued',
    ticketCode: 'DEMO-EVT8-0001',
  ),
];

// ── Today Active Events ─────────────────────────────────────────────────────

/// Events shown in the home Event Now Bar.
/// Event4 is ongoing right now with demoUser checked in.
final List<TodayActiveEvent> demoTodayActiveEvents = [
  TodayActiveEvent(
    event: demoEvents.firstWhere((e) => e.id == DemoWorld.partner2EventId),
    participantStatus: 'checked_in',
  ),
];
