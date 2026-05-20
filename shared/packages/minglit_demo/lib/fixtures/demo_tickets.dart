/// Ticket-domain fixtures: `Ticket`, `TicketTemplate`, `TicketToken`,
/// `SocialInteraction`.
///
/// Owned by **P1-3 agent**. See task #13.
///
/// Exports:
///   - `List<Ticket> demoTickets` — 3 ticket definitions for demoUser's events.
///     Ticket 1: upcoming (selfEvent2, on_sale, KRW 25,000)
///     Ticket 2: past event (partner2Event, on_sale — event already happened)
///     Ticket 3: hidden (selfEvent3 — effectively cancelled/closed sale)
///   - `List<TicketTemplate> demoTicketTemplates` — selfPartner templates
///   - `List<TicketToken> demoTicketTokens` — deterministic QR tokens for
///     ticket 1 (active upcoming ticket)
///   - `List<SocialInteraction> demoSocialInteractions` — 5 interactions:
///     2 likes (partner + party), 1 subscribe, 1 bookmark, 1 block
///
/// FK invariants:
///   - ticket1 → DemoWorld.selfEvent2Id
///   - ticket2 → DemoWorld.partner2EventId
///   - ticket3 → DemoWorld.selfEvent3Id
///   - templates → DemoWorld.selfParty1Id / selfParty2Id
library;

import 'package:minglit_kit/minglit_kit.dart';

import 'demo_world.dart';

// ── Ticket definitions ────────────────────────────────────────────────────────

/// Ticket 1 — upcoming event (selfEvent2), actively on sale.
/// DemoUser has registered for this upcoming event 7 days from now.
final _ticket1CreatedAt = DemoWorld.offset(const Duration(days: -21));

/// Ticket 2 — past event (partner2Event), event occurred 14 days ago.
final _ticket2CreatedAt = DemoWorld.offset(const Duration(days: -20));

/// Ticket 3 — hidden/closed (selfEvent3), sale has ended.
final _ticket3CreatedAt = DemoWorld.offset(const Duration(days: -30));

/// Template created-at anchors.
final _tmpl1CreatedAt = DemoWorld.offset(const Duration(days: -60));
final _tmpl2CreatedAt = DemoWorld.offset(const Duration(days: -55));
final _tmpl3CreatedAt = DemoWorld.offset(const Duration(days: -50));

/// demoUser's ticket definitions — 3 tickets covering upcoming / past / closed
/// sale states.
final List<Ticket> demoTickets = [
  // Ticket 1: upcoming — on sale, event is 7 days out.
  Ticket(
    id: DemoWorld.ticket1Id,
    name: '일반 입장권',
    description: '밍글잇 파티 일반 입장권입니다. 당일 현장 수령 가능합니다.',
    price: 25000,
    quantity: 50,
    soldCount: 23,
    eventId: DemoWorld.selfEvent2Id,
    status: 'on_sale',
    targetEntryGroupIds: const [],
    requiredVerificationIds: const [],
    createdAt: _ticket1CreatedAt,
    updatedAt: _ticket1CreatedAt,
  ),

  // Ticket 2: past event — sale was active, event took place 14 days ago.
  Ticket(
    id: DemoWorld.ticket2Id,
    name: '얼리버드 입장권',
    description: '얼리버드 특가 입장권입니다. 선착순 한정 수량입니다.',
    price: 18000,
    quantity: 30,
    soldCount: 30,
    eventId: DemoWorld.partner2EventId,
    status: 'sold_out',
    targetEntryGroupIds: const [],
    requiredVerificationIds: const [],
    createdAt: _ticket2CreatedAt,
    updatedAt: _ticket2CreatedAt,
  ),

  // Ticket 3: hidden/closed — sale ended, event was cancelled or closed.
  Ticket(
    id: DemoWorld.ticket3Id,
    name: 'VIP 입장권',
    description: 'VIP 전용 입장권입니다. 특별 라운지 이용권 포함.',
    price: 45000,
    quantity: 10,
    soldCount: 4,
    eventId: DemoWorld.selfEvent3Id,
    status: 'hidden',
    targetEntryGroupIds: const [],
    requiredVerificationIds: const [],
    createdAt: _ticket3CreatedAt,
    updatedAt: _ticket3CreatedAt,
  ),
];

// ── Ticket templates ──────────────────────────────────────────────────────────

/// Partner-side ticket templates for selfPartner's parties.
/// These are the reusable templates used when creating new events.
final List<TicketTemplate> demoTicketTemplates = [
  TicketTemplate(
    id: '00000000-0000-4000-8000-500000000001',
    partyId: DemoWorld.selfParty1Id,
    name: '일반 입장권',
    description: '밍글잇 파티 일반 입장권',
    price: 25000,
    quantity: 50,
    targetEntryGroupIds: const [],
    requiredVerificationIds: const [],
    createdAt: _tmpl1CreatedAt,
    updatedAt: _tmpl1CreatedAt,
  ),
  TicketTemplate(
    id: '00000000-0000-4000-8000-500000000002',
    partyId: DemoWorld.selfParty1Id,
    name: 'VIP 입장권',
    description: 'VIP 전용 입장권 — 라운지 이용 포함',
    price: 45000,
    quantity: 10,
    targetEntryGroupIds: const [],
    requiredVerificationIds: const [],
    createdAt: _tmpl2CreatedAt,
    updatedAt: _tmpl2CreatedAt,
  ),
  TicketTemplate(
    id: '00000000-0000-4000-8000-500000000003',
    partyId: DemoWorld.selfParty2Id,
    name: '기본 입장권',
    description: '파티 기본 입장권입니다.',
    price: 15000,
    quantity: 40,
    targetEntryGroupIds: const [],
    requiredVerificationIds: const [],
    createdAt: _tmpl3CreatedAt,
    updatedAt: _tmpl3CreatedAt,
  ),
];

// ── Ticket tokens ─────────────────────────────────────────────────────────────

/// QR tokens for active (upcoming) tickets only.
/// Token values use deterministic UUIDs keyed by ticket index.
/// Signature is a placeholder string — demo QR display does not verify
/// cryptographic signatures (offline-verification path is skipped in demo).
final List<TicketToken> demoTicketTokens = [
  // Token for ticket 1 — upcoming, valid for 7 days out.
  TicketToken(
    ticketId: DemoWorld.ticket1Id,
    eventId: DemoWorld.selfEvent2Id,
    userId: DemoWorld.userId,
    // Deterministic placeholder signature (all-zeros, base64url-encoded 64 bytes).
    signature: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    expiresAt: DemoWorld.offset(const Duration(days: 8)),
  ),
];

// ── Social interactions ───────────────────────────────────────────────────────

/// Demo user's social interactions — a realistic spread of likes, subscribes,
/// bookmarks, and one block.
final List<SocialInteraction> demoSocialInteractions = [
  // Like on partner2's store.
  SocialInteraction(
    userId: DemoWorld.userId,
    targetId: DemoWorld.partner2Id,
    targetType: SocialTargetType.partner,
    interactionType: SocialInteractionType.like,
    createdAt: DemoWorld.offset(const Duration(days: -30)),
  ),

  // Like on selfParty1 (the demo user likes their own party — valid UX).
  SocialInteraction(
    userId: DemoWorld.userId,
    targetId: DemoWorld.selfParty1Id,
    targetType: SocialTargetType.party,
    interactionType: SocialInteractionType.like,
    createdAt: DemoWorld.offset(const Duration(days: -20)),
  ),

  // Subscribe to partner3.
  SocialInteraction(
    userId: DemoWorld.userId,
    targetId: DemoWorld.partner3Id,
    targetType: SocialTargetType.partner,
    interactionType: SocialInteractionType.subscribe,
    createdAt: DemoWorld.offset(const Duration(days: -15)),
  ),

  // Bookmark on partner2's party.
  SocialInteraction(
    userId: DemoWorld.userId,
    targetId: DemoWorld.partner2PartyId,
    targetType: SocialTargetType.party,
    interactionType: SocialInteractionType.bookmark,
    createdAt: DemoWorld.offset(const Duration(days: -10)),
  ),

  // Block on partner5 (tests block filter in feed).
  SocialInteraction(
    userId: DemoWorld.userId,
    targetId: DemoWorld.partner5Id,
    targetType: SocialTargetType.partner,
    interactionType: SocialInteractionType.block,
    createdAt: DemoWorld.offset(const Duration(days: -5)),
  ),
];
