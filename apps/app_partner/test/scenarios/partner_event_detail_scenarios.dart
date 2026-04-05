import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'partner_screenshot_scenario.dart';

class PartnerEventDetailScenarios {
  static final _now = DateTime(2026, 4, 1, 18);

  static Event get _event => Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '프라이빗 네트워킹 나이트',
    startTime: _now.add(const Duration(days: 2)),
    endTime: _now.add(const Duration(days: 2, hours: 4)),
    createdAt: _now,
    updatedAt: _now,
    visibility: 'public',
    currentParticipants: 18,
    maxParticipants: 40,
  );

  static Party get _party => Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '네트워킹 시리즈',
    createdAt: _now,
    updatedAt: _now,
    entryGroups: const [
      PartyEntryGroup(
        id: 'group-1',
        partyId: 'party-1',
        gender: 'male',
        birthYearMin: 1989,
        birthYearMax: 1999,
      ),
    ],
  );

  static List<Ticket> get _tickets => [
    Ticket(
      id: 'ticket-1',
      eventId: 'event-1',
      name: '얼리버드',
      price: 39000,
      quantity: 20,
      soldCount: 14,
      createdAt: _now,
      updatedAt: _now,
      targetEntryGroupIds: const ['group-1'],
    ),
  ];

  static List<EventApplication> get _applications => [
    EventApplication(
      id: 'app-1',
      eventId: 'event-1',
      ticketId: 'ticket-1',
      userId: 'user-1',
      status: 'pending_review',
      createdAt: _now,
      updatedAt: _now,
      user: UserProfile(
        id: 'user-1',
        name: '민준',
        username: 'minjun',
        gender: 'male',
        birthDate: DateTime(1995, 2, 12),
      ),
    ),
    EventApplication(
      id: 'app-2',
      eventId: 'event-1',
      ticketId: 'ticket-1',
      userId: 'user-2',
      status: 'approved',
      createdAt: _now.subtract(const Duration(hours: 3)),
      updatedAt: _now.subtract(const Duration(hours: 2)),
      user: UserProfile(
        id: 'user-2',
        name: '서연',
        username: 'seoyeon',
        gender: 'female',
        birthDate: DateTime(1997, 7, 21),
      ),
    ),
  ];

  static List<dynamic> _buildOverrides() {
    final mockEventRepo = MockEventRepository();
    final mockTicketRepo = MockTicketRepository();
    final mockPartyRepo = MockPartyRepository();

    when(
      () => mockEventRepo.getEventById('event-1'),
    ).thenAnswer((_) async => _event);
    when(
      () => mockEventRepo.getApplicationsByEventId('event-1'),
    ).thenAnswer((_) async => _applications);
    when(
      () => mockTicketRepo.getTicketsByEventId('event-1'),
    ).thenAnswer((_) async => _tickets);
    when(
      () => mockPartyRepo.getPartyById('party-1'),
    ).thenAnswer((_) async => _party);

    return [
      eventRepositoryProvider.overrideWithValue(mockEventRepo),
      ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
      partyRepositoryProvider.overrideWithValue(mockPartyRepo),
    ];
  }

  static List<PartnerScreenshotScenario> get all => [
    PartnerScreenshotScenario(
      name: 'partner_event_detail_page_operation',
      page: const EventDetailPage(eventId: 'event-1'),
      overrides: _buildOverrides(),
    ),
    PartnerScreenshotScenario(
      name: 'partner_event_detail_page_applications',
      page: const EventDetailPage(eventId: 'event-1'),
      brightness: Brightness.dark,
      overrides: _buildOverrides(),
    ),
  ];
}
