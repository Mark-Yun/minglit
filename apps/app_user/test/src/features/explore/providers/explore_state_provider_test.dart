import 'package:app_user/src/features/explore/logic/eligibility_filter.dart';
import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  final now = DateTime.now();

  // Fix #1534: 검색 결과가 party.title/tickets 없이 반환되어 '제목 없음'/'가격 미정' 표시 버그 회귀 방지
  group('searchResults — Fix #1534', () {
    test('searchEvents()를 호출하여 party와 tickets가 포함된 이벤트를 반환한다', () async {
      final mockRepo = MockEventRepository();
      final party = Party(
        id: 'p1',
        partnerId: 'partner1',
        title: '테스트 파티',
        createdAt: now,
        updatedAt: now,
      );
      final ticket = Ticket(
        id: 't1',
        name: '일반',
        price: 15000,
        createdAt: now,
        updatedAt: now,
      );
      final event = Event(
        id: 'e1',
        partyId: 'p1',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        createdAt: now,
        updatedAt: now,
        party: party,
        tickets: [ticket],
      );

      when(() => mockRepo.searchEvents('파티')).thenAnswer((_) async => [event]);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      container.read(searchQueryProvider.notifier).update('파티');
      final result = await container.read(searchResultsProvider.future);

      expect(result, hasLength(1));
      // party.title이 있어 '제목 없음' 대신 실제 제목이 표시 가능
      expect(result.first.party?.title, '테스트 파티');
      // tickets가 있어 '가격 미정' 대신 실제 가격이 표시 가능
      expect(result.first.tickets?.first.price, 15000);
      verify(() => mockRepo.searchEvents('파티')).called(1);
    });

    test('빈 쿼리는 searchEvents를 호출하지 않고 빈 목록을 반환한다', () async {
      final mockRepo = MockEventRepository();
      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      // query is empty by default
      final result = await container.read(searchResultsProvider.future);

      expect(result, isEmpty);
      verifyNever(() => mockRepo.searchEvents(any()));
    });
  });

  Event makeEvent({
    String id = 'e1',
    List<Ticket>? tickets,
  }) {
    return Event(
      id: id,
      partyId: 'p1',
      startTime: now.add(const Duration(days: 1)),
      endTime: now.add(const Duration(days: 1, hours: 2)),
      createdAt: now,
      updatedAt: now,
      tickets: tickets,
    );
  }

  Ticket makeTicket({
    String id = 't1',
    int price = 10000,
  }) {
    return Ticket(
      id: id,
      name: 'Ticket $id',
      createdAt: now,
      updatedAt: now,
      price: price,
    );
  }

  group('filteredEventsProvider \u2014 eligibility filter'
      ' with verification check', () {
    test('unverified user with eligibilityEnabled: true sees all events', () {
      final events = [
        makeEvent(tickets: [makeTicket()]),
        makeEvent(
          id: 'e2',
          tickets: [makeTicket(id: 't2')],
        ),
      ];

      final container = createContainer(
        overrides: [
          bulkEligibilityDataProvider.overrideWith(
            (ref) async => BulkEligibilityData.fromJson({
              'user_profile': {
                'gender': 'male',
                'birth_year': 1995,
                'is_verified': false, // Unverified
              },
              'approved_verifications': <dynamic>[],
            }),
          ),
        ],
      );

      // Enable eligibility filter
      container.read(activeFiltersProvider.notifier).toggleEligibility();

      // Even though eligibilityEnabled is true, unverified
      // users should see all events because the filter
      // is skipped for unverified users
      final result = container.read(
        filteredEventsProvider(events: events),
      );

      expect(result, hasLength(2));
      expect(result.map((e) => e.id), containsAll(['e1', 'e2']));
    });

    test(
      'verified user with eligibilityEnabled: true sees filtered events',
      () async {
        final events = [
          makeEvent(tickets: [makeTicket()]),
          makeEvent(
            id: 'e2',
            tickets: [makeTicket(id: 't2')],
          ),
        ];

        final container = createContainer(
          overrides: [
            bulkEligibilityDataProvider.overrideWith(
              (ref) async => BulkEligibilityData.fromJson({
                'user_profile': {
                  'gender': 'male',
                  'birth_year': 1995,
                  'is_verified': true, // Verified
                },
                'approved_verifications': <dynamic>[
                  {
                    'partner_id': 'p1',
                    'verification_id': 'v1',
                    'verified_at': '2025-01-01',
                  },
                ],
              }),
            ),
          ],
        );

        // Enable eligibility filter
        container.read(activeFiltersProvider.notifier).toggleEligibility();

        // Wait for the async bulkEligibilityDataProvider to resolve
        await container.read(bulkEligibilityDataProvider.future);

        // Verified users with approved verifications should see filtered events
        final result = container.read(
          filteredEventsProvider(events: events),
        );

        // Since tickets have no required verifications, they should be eligible
        expect(result, hasLength(2));
      },
    );
    test(
      'eligibilityEnabled: false shows all events regardless of verification',
      () {
        final events = [
          makeEvent(tickets: [makeTicket()]),
          makeEvent(
            id: 'e2',
            tickets: [makeTicket(id: 't2')],
          ),
        ];

        final container = createContainer(
          overrides: [
            bulkEligibilityDataProvider.overrideWith(
              (ref) async => BulkEligibilityData.fromJson({
                'user_profile': {
                  'gender': 'male',
                  'birth_year': 1995,
                  'is_verified': false,
                },
                'approved_verifications': <dynamic>[],
              }),
            ),
          ],
        );

        // Do NOT enable eligibility filter (default is false)
        // Result should be all events

        final result = container.read(
          filteredEventsProvider(events: events),
        );

        expect(result, hasLength(2));
        expect(result.map((e) => e.id), containsAll(['e1', 'e2']));
      },
    );

    test(
      'null eligibility data returns all events when eligibilityEnabled: true',
      () {
        final events = [
          makeEvent(tickets: [makeTicket()]),
          makeEvent(
            id: 'e2',
            tickets: [makeTicket(id: 't2')],
          ),
        ];

        final container = createContainer(
          overrides: [
            bulkEligibilityDataProvider.overrideWith(
              (ref) async => null, // No eligibility data
            ),
          ],
        );

        // Enable eligibility filter
        container.read(activeFiltersProvider.notifier).toggleEligibility();

        // When eligibility data is null, filter is skipped
        final result = container.read(
          filteredEventsProvider(events: events),
        );

        expect(result, hasLength(2));
        expect(result.map((e) => e.id), containsAll(['e1', 'e2']));
      },
    );

    test('unverified user with null userProfile sees all events', () {
      final events = [
        makeEvent(tickets: [makeTicket()]),
        makeEvent(
          id: 'e2',
          tickets: [makeTicket(id: 't2')],
        ),
      ];

      final container = createContainer(
        overrides: [
          bulkEligibilityDataProvider.overrideWith(
            (ref) async => BulkEligibilityData.fromJson({
              'user_profile': null, // No profile
              'approved_verifications': <dynamic>[],
            }),
          ),
        ],
      );

      // Enable eligibility filter
      container.read(activeFiltersProvider.notifier).toggleEligibility();

      // When userProfile is null, the condition
      // (eligibility.userProfile?.isVerified == true) is false,
      // so filter is skipped
      final result = container.read(
        filteredEventsProvider(events: events),
      );

      expect(result, hasLength(2));
      expect(result.map((e) => e.id), containsAll(['e1', 'e2']));
    });
  });
}
