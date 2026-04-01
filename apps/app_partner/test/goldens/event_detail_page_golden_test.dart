@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import '../utils/partner_golden_test_helpers.dart';

void main() {
  late MockEventRepository mockEventRepository;
  late MockTicketRepository mockTicketRepository;
  late MockPartyRepository mockPartyRepository;
  final now = DateTime(2026, 4, 1, 18);

  final event = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '프라이빗 네트워킹 나이트',
    startTime: now.add(const Duration(days: 2)),
    endTime: now.add(const Duration(days: 2, hours: 4)),
    createdAt: now,
    updatedAt: now,
    visibility: 'public',
    currentParticipants: 18,
    maxParticipants: 40,
  );

  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '네트워킹 시리즈',
    createdAt: now,
    updatedAt: now,
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

  final tickets = [
    Ticket(
      id: 'ticket-1',
      eventId: 'event-1',
      name: '얼리버드',
      price: 39000,
      quantity: 20,
      soldCount: 14,
      createdAt: now,
      updatedAt: now,
      targetEntryGroupIds: const ['group-1'],
    ),
  ];

  final applications = [
    EventApplication(
      id: 'app-1',
      eventId: 'event-1',
      ticketId: 'ticket-1',
      userId: 'user-1',
      status: 'pending_review',
      createdAt: now,
      updatedAt: now,
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
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      user: UserProfile(
        id: 'user-2',
        name: '서연',
        username: 'seoyeon',
        gender: 'female',
        birthDate: DateTime(1997, 7, 21),
      ),
    ),
  ];

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  setUp(() {
    mockEventRepository = MockEventRepository();
    mockTicketRepository = MockTicketRepository();
    mockPartyRepository = MockPartyRepository();
  });

  goldenTest(
    'Partner EventDetailPage operation tab',
    fileName: 'partner_event_detail_page_operation',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
    },
    builder: () {
      when(
        () => mockEventRepository.getEventById('event-1'),
      ).thenAnswer((_) async => event);
      when(
        () => mockEventRepository.getApplicationsByEventId('event-1'),
      ).thenAnswer((_) async => applications);
      when(
        () => mockTicketRepository.getTicketsByEventId('event-1'),
      ).thenAnswer((_) async => tickets);
      when(
        () => mockPartyRepository.getPartyById('party-1'),
      ).thenAnswer((_) async => party);

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'operation tab',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const EventDetailPage(eventId: 'event-1'),
                overrides: [
                  eventRepositoryProvider.overrideWithValue(
                    mockEventRepository,
                  ),
                  ticketRepositoryProvider.overrideWithValue(
                    mockTicketRepository,
                  ),
                  partyRepositoryProvider.overrideWithValue(
                    mockPartyRepository,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'Partner EventDetailPage applications tab',
    fileName: 'partner_event_detail_page_applications',
    pumpBeforeTest: (tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('참가 신청'));
      await tester.pumpAndSettle();
    },
    builder: () {
      when(
        () => mockEventRepository.getEventById('event-1'),
      ).thenAnswer((_) async => event);
      when(
        () => mockEventRepository.getApplicationsByEventId('event-1'),
      ).thenAnswer((_) async => applications);
      when(
        () => mockTicketRepository.getTicketsByEventId('event-1'),
      ).thenAnswer((_) async => tickets);
      when(
        () => mockPartyRepository.getPartyById('party-1'),
      ).thenAnswer((_) async => party);

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'applications tab',
            child: SizedBox(
              width: 390,
              height: 844,
              child: PartnerGoldenPageWrapper(
                page: const EventDetailPage(eventId: 'event-1'),
                brightness: Brightness.dark,
                overrides: [
                  eventRepositoryProvider.overrideWithValue(
                    mockEventRepository,
                  ),
                  ticketRepositoryProvider.overrideWithValue(
                    mockTicketRepository,
                  ),
                  partyRepositoryProvider.overrideWithValue(
                    mockPartyRepository,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
