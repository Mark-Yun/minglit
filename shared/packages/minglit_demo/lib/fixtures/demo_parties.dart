/// Party-domain fixtures: `Party`, `EntryGroupTemplate`, `Tag`.
///
/// Owned by **P1-2 agent**. See task #12.
///
/// Required exports:
///   - `List<Party> demoParties` — 6 parties (2 for selfPartner, 1 each for
///     partner2-5)
///   - `List<EntryGroupTemplate> demoEntryGroups` — entry group templates per
///     party
///   - `List<Tag> demoTags` — 10 tags covering common social interests
///
/// Constraints:
///   - FK: `partner_id` matches demo_world.dart partner IDs
///   - Each Party is referenced by demo_events.dart via partyId
library;

import 'package:minglit_kit/minglit_data.dart';

import 'demo_world.dart';

// ── Tags ───────────────────────────────────────────────────────────────────

/// 10 featured tags covering common social-event themes.
final List<Tag> demoTags = [
  const Tag(
    id: '00000000-0000-4000-8000-700000000001',
    name: '음악',
    isFeatured: true,
    usageCount: 42,
    recentCount: 8,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000002',
    name: '술',
    isFeatured: true,
    usageCount: 38,
    recentCount: 11,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000003',
    name: '대화',
    isFeatured: true,
    usageCount: 55,
    recentCount: 15,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000004',
    name: '게임',
    isFeatured: true,
    usageCount: 29,
    recentCount: 7,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000005',
    name: '운동',
    isFeatured: false,
    usageCount: 21,
    recentCount: 5,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000006',
    name: '영화',
    isFeatured: false,
    usageCount: 18,
    recentCount: 4,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000007',
    name: '음식',
    isFeatured: true,
    usageCount: 33,
    recentCount: 9,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000008',
    name: '예술',
    isFeatured: false,
    usageCount: 16,
    recentCount: 6,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000009',
    name: '독서',
    isFeatured: false,
    usageCount: 12,
    recentCount: 3,
  ),
  const Tag(
    id: '00000000-0000-4000-8000-700000000010',
    name: '여행',
    isFeatured: false,
    usageCount: 9,
    recentCount: 2,
  ),
];

// ── Entry Group Templates ──────────────────────────────────────────────────

/// Entry group templates (party-level conditions).
final List<EntryGroupTemplate> demoEntryGroups = [
  // selfParty1: no restrictions — 성별 무관
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000001',
    partyId: DemoWorld.selfParty1Id,
    label: '일반',
    createdAt: DemoWorld.offset(const Duration(days: -30)),
    updatedAt: DemoWorld.offset(const Duration(days: -30)),
  ),

  // selfParty2: male group + female group (balanced)
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000002',
    partyId: DemoWorld.selfParty2Id,
    label: '남성',
    gender: 'male',
    createdAt: DemoWorld.offset(const Duration(days: -28)),
    updatedAt: DemoWorld.offset(const Duration(days: -28)),
  ),
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000003',
    partyId: DemoWorld.selfParty2Id,
    label: '여성',
    gender: 'female',
    createdAt: DemoWorld.offset(const Duration(days: -28)),
    updatedAt: DemoWorld.offset(const Duration(days: -28)),
  ),

  // partner2Party: no restrictions
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000004',
    partyId: DemoWorld.partner2PartyId,
    label: '일반',
    createdAt: DemoWorld.offset(const Duration(days: -20)),
    updatedAt: DemoWorld.offset(const Duration(days: -20)),
  ),

  // partner3Party: 2000년대생 이후 (younger crowd, art scene)
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000005',
    partyId: DemoWorld.partner3PartyId,
    label: '일반',
    birthYearMin: 1995,
    birthYearMax: 2005,
    createdAt: DemoWorld.offset(const Duration(days: -18)),
    updatedAt: DemoWorld.offset(const Duration(days: -18)),
  ),

  // partner4Party: no restrictions (running crew, open to all)
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000006',
    partyId: DemoWorld.partner4PartyId,
    label: '일반',
    createdAt: DemoWorld.offset(const Duration(days: -15)),
    updatedAt: DemoWorld.offset(const Duration(days: -15)),
  ),

  // partner5Party: no restrictions (brunch social)
  EntryGroupTemplate(
    id: '00000000-0000-4000-8000-800000000007',
    partyId: DemoWorld.partner5PartyId,
    label: '일반',
    createdAt: DemoWorld.offset(const Duration(days: -12)),
    updatedAt: DemoWorld.offset(const Duration(days: -12)),
  ),
];

// ── Locations ──────────────────────────────────────────────────────────────

const _loc1Id = '00000000-0000-4000-8000-900000000001';
const _loc2Id = '00000000-0000-4000-8000-900000000002';
const _loc3Id = '00000000-0000-4000-8000-900000000003';
const _loc4Id = '00000000-0000-4000-8000-900000000004';
const _loc5Id = '00000000-0000-4000-8000-900000000005';
const _loc6Id = '00000000-0000-4000-8000-900000000006';

final _demoLocations = [
  Location(
    id: _loc1Id,
    partnerId: DemoWorld.selfPartnerId,
    name: '루프탑 라운지 강남',
    address: '서울특별시 강남구 테헤란로 123',
    addressDetail: '5층',
    region1: '서울',
    region2: '강남구',
    region3: '역삼동',
    latitude: 37.5013,
    longitude: 127.0397,
    createdAt: DemoWorld.offset(const Duration(days: -60)),
    updatedAt: DemoWorld.offset(const Duration(days: -60)),
  ),
  Location(
    id: _loc2Id,
    partnerId: DemoWorld.selfPartnerId,
    name: '이태원 소셜 클럽',
    address: '서울특별시 용산구 이태원로 45',
    region1: '서울',
    region2: '용산구',
    region3: '이태원동',
    latitude: 37.5345,
    longitude: 126.9944,
    createdAt: DemoWorld.offset(const Duration(days: -55)),
    updatedAt: DemoWorld.offset(const Duration(days: -55)),
  ),
  Location(
    id: _loc3Id,
    partnerId: DemoWorld.partner2Id,
    name: '홍대 시네마 카페',
    address: '서울특별시 마포구 홍익로 12',
    region1: '서울',
    region2: '마포구',
    region3: '상수동',
    latitude: 37.5511,
    longitude: 126.9247,
    createdAt: DemoWorld.offset(const Duration(days: -45)),
    updatedAt: DemoWorld.offset(const Duration(days: -45)),
  ),
  Location(
    id: _loc4Id,
    partnerId: DemoWorld.partner3Id,
    name: '성수 아트 스튜디오',
    address: '서울특별시 성동구 연무장길 8',
    region1: '서울',
    region2: '성동구',
    region3: '성수동',
    latitude: 37.5446,
    longitude: 127.0556,
    createdAt: DemoWorld.offset(const Duration(days: -40)),
    updatedAt: DemoWorld.offset(const Duration(days: -40)),
  ),
  Location(
    id: _loc5Id,
    partnerId: DemoWorld.partner4Id,
    name: '한강 공원 여의도 게이트',
    address: '서울특별시 영등포구 여의동로 330',
    region1: '서울',
    region2: '영등포구',
    region3: '여의도동',
    latitude: 37.5284,
    longitude: 126.9322,
    createdAt: DemoWorld.offset(const Duration(days: -35)),
    updatedAt: DemoWorld.offset(const Duration(days: -35)),
  ),
  Location(
    id: _loc6Id,
    partnerId: DemoWorld.partner5Id,
    name: '망원 브런치 하우스',
    address: '서울특별시 마포구 망원로 77',
    region1: '서울',
    region2: '마포구',
    region3: '망원동',
    latitude: 37.5558,
    longitude: 126.9034,
    createdAt: DemoWorld.offset(const Duration(days: -30)),
    updatedAt: DemoWorld.offset(const Duration(days: -30)),
  ),
];

// ── Parties ────────────────────────────────────────────────────────────────

/// 6 parties: 2 for selfPartner, 1 each for partner2-5.
final List<Party> demoParties = [
  // selfPartner — Party 1: Wine & Jazz (active)
  Party(
    id: DemoWorld.selfParty1Id,
    partnerId: DemoWorld.selfPartnerId,
    title: '강남 와인 & 재즈 소셜',
    description: {
      'ops': [
        {'insert': '매월 열리는 와인 & 라이브 재즈 소셜 파티. 새로운 사람들과 여유롭게 대화를 즐겨보세요.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/party1/800/400'],
    locationId: _loc1Id,
    location: _demoLocations[0],
    maxParticipants: 30,
    status: 'active',
    visibility: 'public',
    createdAt: DemoWorld.offset(const Duration(days: -60)),
    updatedAt: DemoWorld.offset(const Duration(days: -7)),
    tags: [
      demoTags.firstWhere((t) => t.name == '음악'),
      demoTags.firstWhere((t) => t.name == '대화'),
      demoTags.firstWhere((t) => t.name == '술'),
    ],
    entryGroups: [demoEntryGroups[0]],
  ),

  // selfPartner — Party 2: Boardgame Night (active)
  Party(
    id: DemoWorld.selfParty2Id,
    partnerId: DemoWorld.selfPartnerId,
    title: '이태원 보드게임 나잇',
    description: {
      'ops': [
        {'insert': '격주로 열리는 보드게임 파티. 남녀 균형 맞춤 / 게임 초보 환영!\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/party2/800/400'],
    locationId: _loc2Id,
    location: _demoLocations[1],
    maxParticipants: 24,
    status: 'active',
    visibility: 'public',
    createdAt: DemoWorld.offset(const Duration(days: -55)),
    updatedAt: DemoWorld.offset(const Duration(days: -10)),
    tags: [
      demoTags.firstWhere((t) => t.name == '게임'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    entryGroups: [demoEntryGroups[1], demoEntryGroups[2]],
  ),

  // partner2 — Party: Cinema Café (active)
  Party(
    id: DemoWorld.partner2PartyId,
    partnerId: DemoWorld.partner2Id,
    title: '홍대 영화 토크 클럽',
    description: {
      'ops': [
        {'insert': '한 달에 한 편, 함께 보고 함께 이야기하는 영화 소모임.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/party3/800/400'],
    locationId: _loc3Id,
    location: _demoLocations[2],
    maxParticipants: 16,
    status: 'active',
    visibility: 'public',
    createdAt: DemoWorld.offset(const Duration(days: -45)),
    updatedAt: DemoWorld.offset(const Duration(days: -5)),
    tags: [
      demoTags.firstWhere((t) => t.name == '영화'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    entryGroups: [demoEntryGroups[3]],
  ),

  // partner3 — Party: Art Studio (active)
  Party(
    id: DemoWorld.partner3PartyId,
    partnerId: DemoWorld.partner3Id,
    title: '성수 아트 드로잉 파티',
    description: {
      'ops': [
        {'insert': '그림 실력 무관! 성수 스튜디오에서 함께 그리고 친해지는 시간.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/party4/800/400'],
    locationId: _loc4Id,
    location: _demoLocations[3],
    maxParticipants: 20,
    status: 'active',
    visibility: 'public',
    createdAt: DemoWorld.offset(const Duration(days: -40)),
    updatedAt: DemoWorld.offset(const Duration(days: -6)),
    tags: [
      demoTags.firstWhere((t) => t.name == '예술'),
    ],
    entryGroups: [demoEntryGroups[4]],
  ),

  // partner4 — Party: Running Crew (active)
  Party(
    id: DemoWorld.partner4PartyId,
    partnerId: DemoWorld.partner4Id,
    title: '한강 러닝 크루',
    description: {
      'ops': [
        {'insert': '매주 일요일 아침 한강 공원을 함께 달려요. 5km, 10km 코스 선택 가능.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/party5/800/400'],
    locationId: _loc5Id,
    location: _demoLocations[4],
    maxParticipants: 40,
    status: 'active',
    visibility: 'public',
    createdAt: DemoWorld.offset(const Duration(days: -35)),
    updatedAt: DemoWorld.offset(const Duration(days: -8)),
    tags: [
      demoTags.firstWhere((t) => t.name == '운동'),
    ],
    entryGroups: [demoEntryGroups[5]],
  ),

  // partner5 — Party: Brunch Social (active)
  Party(
    id: DemoWorld.partner5PartyId,
    partnerId: DemoWorld.partner5Id,
    title: '망원 브런치 소셜 클럽',
    description: {
      'ops': [
        {'insert': '주말 오전, 맛있는 브런치를 함께. 새로운 사람들과 여유롭게 시작하는 주말.\n'},
      ],
    },
    imageUrls: ['https://picsum.photos/seed/party6/800/400'],
    locationId: _loc6Id,
    location: _demoLocations[5],
    maxParticipants: 25,
    status: 'active',
    visibility: 'public',
    createdAt: DemoWorld.offset(const Duration(days: -30)),
    updatedAt: DemoWorld.offset(const Duration(days: -4)),
    tags: [
      demoTags.firstWhere((t) => t.name == '음식'),
      demoTags.firstWhere((t) => t.name == '대화'),
    ],
    entryGroups: [demoEntryGroups[6]],
  ),
];
