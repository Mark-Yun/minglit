import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event_feed_type.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late EventRepository repository;

  final now = DateTime.now();
  final mockUser = MockUser();

  final eventJson = {
    'id': 'event_1',
    'party_id': 'party_1',
    'title': '강남 밍글릿 이벤트',
    'status': 'scheduled',
    'start_time': now.add(const Duration(days: 7)).toIso8601String(),
    'end_time': now.add(const Duration(days: 7, hours: 3)).toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  final applicationJson = {
    'id': 'app_1',
    'event_id': 'event_1',
    'user_id': 'user_1',
    'ticket_id': 'ticket_1',
    'status': 'confirmed',
    'payment_id': 'pay_123',
    'payment_amount': 30000,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    repository = EventRepository(supabase: mockClient);
  });

  group('EventRepository Queries', () {
    group('getEventById', () {
      test('returns event with relations', () async {
        unawaited(mockTable(mockClient, 'events', singleData: eventJson));

        final result = await repository.getEventById('event_1');

        expect(result.id, 'event_1');
        expect(result.title, '강남 밍글릿 이벤트');
        expect(result.status, 'scheduled');
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('not found'),
          ),
        );

        await expectLater(
          repository.getEventById('event_unknown'),
          throwsA(anything),
        );
      });
    });

    group('getApplication', () {
      test('returns application when found', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            maybeSingleData: applicationJson,
          ),
        );

        final result = await repository.getApplication(
          eventId: 'event_1',
          userId: 'user_1',
        );

        expect(result, isNotNull);
        expect(result!.id, 'app_1');
        expect(result.status, 'confirmed');
      });

      test('returns null when not found', () async {
        unawaited(mockTable(mockClient, 'event_applications'));

        final result = await repository.getApplication(
          eventId: 'event_1',
          userId: 'user_unknown',
        );

        expect(result, isNull);
      });
    });

    group('checkApplicationStatus', () {
      test('returns true for confirmed application', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            maybeSingleData: applicationJson,
          ),
        );

        final result = await repository.checkApplicationStatus(
          eventId: 'event_1',
          userId: 'user_1',
        );

        expect(result, isTrue);
      });

      test('returns false when no application', () async {
        unawaited(mockTable(mockClient, 'event_applications'));

        final result = await repository.checkApplicationStatus(
          eventId: 'event_1',
          userId: 'user_1',
        );

        expect(result, isFalse);
      });

      test('returns false for rejected application', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            maybeSingleData: {...applicationJson, 'status': 'rejected'},
          ),
        );

        final result = await repository.checkApplicationStatus(
          eventId: 'event_1',
          userId: 'user_1',
        );

        expect(result, isFalse);
      });

      test('returns false for cancelled application', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            maybeSingleData: {...applicationJson, 'status': 'cancelled'},
          ),
        );

        final result = await repository.checkApplicationStatus(
          eventId: 'event_1',
          userId: 'user_1',
        );

        expect(result, isFalse);
      });
    });

    group('getMyPurchaseHistory', () {
      test('returns purchase history for user', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [applicationJson],
          ),
        );

        final result = await repository.getMyPurchaseHistory('user_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'app_1');
      });

      test('returns empty list when no purchases', () async {
        unawaited(
          mockTable(mockClient, 'event_applications', selectData: []),
        );

        final result = await repository.getMyPurchaseHistory('user_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('history error'),
          ),
        );

        await expectLater(
          repository.getMyPurchaseHistory('user_1'),
          throwsA(anything),
        );
      });
    });

    group('getRequestedRefundCountForPartner', () {
      test('returns exact count for requested refunds', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            countValue: 2,
          ),
        );

        final result = await repository.getRequestedRefundCountForPartner(
          'partner_1',
        );

        expect(result, 2);
      });

      test('returns zero when there are no requested refunds', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
          ),
        );

        final result = await repository.getRequestedRefundCountForPartner(
          'partner_1',
        );

        expect(result, 0);
      });

      test('rethrows when query throws', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('query failed'),
          ),
        );

        await expectLater(
          repository.getRequestedRefundCountForPartner('partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getMyTickets', () {
      test('returns only paid/approved tickets', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [
              {...applicationJson, 'status': 'paid'},
              {...applicationJson, 'id': 'app_2', 'status': 'approved'},
            ],
          ),
        );

        final result = await repository.getMyTickets('user_1');

        expect(result, hasLength(2));
        expect(result.first.id, 'app_1');
        expect(result.first.status, 'paid');
        expect(result.last.id, 'app_2');
        expect(result.last.status, 'approved');
      });

      test('returns empty list when no active tickets', () async {
        unawaited(
          mockTable(mockClient, 'event_applications', selectData: []),
        );

        final result = await repository.getMyTickets('user_1');

        expect(result, isEmpty);
      });

      test('includes event and ticket relations', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [
              {
                ...applicationJson,
                'status': 'paid',
                'event': eventJson,
                'ticket': {
                  'id': 'ticket_1',
                  'event_id': 'event_1',
                  'name': '일반 티켓',
                  'price': 30000,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              },
            ],
          ),
        );

        final result = await repository.getMyTickets('user_1');

        expect(result, hasLength(1));
        expect(result.first.event, isNotNull);
        expect(result.first.event!.id, 'event_1');
        expect(result.first.ticket, isNotNull);
        expect(result.first.ticket!.id, 'ticket_1');
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('tickets error'),
          ),
        );

        await expectLater(
          repository.getMyTickets('user_1'),
          throwsA(anything),
        );
      });
    });

    // Fix #1597: getPendingApplicationCount uses 2-step query.
    // Step 1: events filtered by partner (1-level join, reliable).
    // Step 2: count event_applications by event_id + status.
    group('getPendingApplicationCount', () {
      test('returns pending count from event_applications', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            selectData: [
              {'id': 'event_1', 'party': <String, dynamic>{}},
              {'id': 'event_2', 'party': <String, dynamic>{}},
            ],
          ),
        );
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [
              {'id': 'app_1'},
              {'id': 'app_2'},
            ],
            countValue: 2,
          ),
        );

        final result = await repository.getPendingApplicationCount('partner_1');

        expect(result, 2);
      });

      test('includes pending_review status in count', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            selectData: [
              {'id': 'event_1', 'party': <String, dynamic>{}},
            ],
          ),
        );
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [
              {'id': 'app_3'},
            ],
            countValue: 1,
          ),
        );

        final result = await repository.getPendingApplicationCount('partner_1');

        expect(result, 1);
      });

      test('returns 0 when no future events', () async {
        unawaited(
          mockTable(mockClient, 'events', selectData: []),
        );

        final result = await repository.getPendingApplicationCount('partner_1');

        expect(result, 0);
      });

      test('returns 0 when no pending applications', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            selectData: [
              {'id': 'event_1', 'party': <String, dynamic>{}},
            ],
          ),
        );
        unawaited(
          mockTable(mockClient, 'event_applications', selectData: []),
        );

        final result = await repository.getPendingApplicationCount('partner_1');

        expect(result, 0);
      });

      test(
        'step-1 filters by partner_id, start_time, and applies limit(500) matching getPartnerFutureEvents scope; step-2 filters by event_id and status',
        () async {
          // Note: .limit(500) and .order('start_time') are applied in step-1 to guarantee
          // count and tab (getPartnerFutureEvents) share identical event scope.
          // The mock does not capture limit/order calls, so those are verified by
          // code review and integration tests only.
          final eventsTable = mockTable(
            mockClient,
            'events',
            selectData: [
              {'id': 'event_1', 'party': <String, dynamic>{}},
            ],
          );
          final appsTable = mockTable(mockClient, 'event_applications');

          await repository.getPendingApplicationCount('partner_1');

          // Step 1: events table must filter partner and start_time
          expect(
            eventsTable.recordedFilters,
            contains(
              predicate<RecordedFilterOperation>(
                (f) =>
                    f.method == 'eq' &&
                    f.column == 'party.partner_id' &&
                    f.value == 'partner_1',
              ),
            ),
          );
          expect(
            eventsTable.recordedFilters,
            contains(
              predicate<RecordedFilterOperation>(
                (f) => f.method == 'gte' && f.column == 'start_time',
              ),
            ),
          );

          // Step 2: applications table must filter by event_id and status
          expect(
            appsTable.recordedFilters,
            contains(
              predicate<RecordedFilterOperation>(
                (f) =>
                    f.method == 'inFilter' &&
                    f.column == 'event_id' &&
                    (f.value! as List).contains('event_1'),
              ),
            ),
          );
          expect(
            appsTable.recordedFilters,
            contains(
              predicate<RecordedFilterOperation>(
                (f) =>
                    f.method == 'inFilter' &&
                    f.column == 'status' &&
                    (f.value! as List).contains('pending_review'),
              ),
            ),
          );
        },
      );

      test('returns 0 on error in step-1 (fail-safe)', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('db error'),
          ),
        );

        final result = await repository.getPendingApplicationCount('partner_1');

        expect(result, 0);
      });

      test('returns 0 on error in step-2 (fail-safe)', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            selectData: [
              {'id': 'event_1', 'party': <String, dynamic>{}},
            ],
          ),
        );
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('db error'),
          ),
        );

        final result = await repository.getPendingApplicationCount('partner_1');

        expect(result, 0);
      });
    });

    // Fix #1597: getPartnerFutureEvents fetches all future events without 7-day upper bound.
    group('getPartnerFutureEvents', () {
      test('returns future events for partner', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            selectData: [eventJson],
          ),
        );

        final result = await repository.getPartnerFutureEvents('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_1');
      });

      test('returns empty list when no future events', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            selectData: [],
          ),
        );

        final result = await repository.getPartnerFutureEvents('partner_1');

        expect(result, isEmpty);
      });

      test('filters to start_time >= now with no upper-date bound', () async {
        final eventsTable = mockTable(
          mockClient,
          'events',
          selectData: [],
        );

        await repository.getPartnerFutureEvents('partner_1');

        expect(
          eventsTable.recordedFilters,
          contains(
            predicate<RecordedFilterOperation>(
              (f) => f.method == 'gte' && f.column == 'start_time',
            ),
          ),
        );
        // No upper-date filter — events beyond 7 days are included (row limit handles safety).
        expect(
          eventsTable.recordedFilters.where(
            (f) => f.method == 'lte' && f.column == 'start_time',
          ),
          isEmpty,
        );
      });

      test('throws on error (no fail-safe)', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('db error'),
          ),
        );

        await expectLater(
          repository.getPartnerFutureEvents('partner_1'),
          throwsA(anything),
        );
      });
    });

    group('getTicketBalanceStatus', () {
      test('returns ticket balance map', () async {
        when(
          () => mockClient.rpc<List<dynamic>?>(
            'get_event_ticket_balance_status',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<List<dynamic>?>([
            {'ticket_id': 't_1', 'allowed': true},
            {'ticket_id': 't_2', 'allowed': false},
          ]),
        );

        final result = await repository.getTicketBalanceStatus('event_1');

        expect(result, hasLength(2));
        expect(result['t_1'], isTrue);
        expect(result['t_2'], isFalse);
      });

      test('returns empty map when no tickets', () async {
        when(
          () => mockClient.rpc<List<dynamic>?>(
            'get_event_ticket_balance_status',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<List<dynamic>?>(<dynamic>[]));

        final result = await repository.getTicketBalanceStatus('event_1');

        expect(result, isEmpty);
      });

      test('returns empty map when RPC returns null', () async {
        when(
          () => mockClient.rpc<List<dynamic>?>(
            'get_event_ticket_balance_status',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<List<dynamic>?>(null));

        final result = await repository.getTicketBalanceStatus('event_1');

        expect(result, isEmpty);
      });
    });

    group('getApplicationsByEventId', () {
      test('returns mapped applications from RPC', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_event_applications_with_user',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<dynamic>([
            {
              'application_id': 'app_1',
              'event_id': 'event_1',
              'ticket_id': 'ticket_1',
              'user_id': 'user_1',
              'payment_id': 'pay_123',
              'payment_amount': 30000,
              'status': 'confirmed',
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              'user_name': '홍길동',
              'user_phone': '010-1234-5678',
            },
          ]),
        );

        final result = await repository.getApplicationsByEventId('event_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'app_1');
        expect(result.first.user?.name, '홍길동');
      });

      test('returns empty list when no applications', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_event_applications_with_user',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<dynamic>(<dynamic>[]));

        final result = await repository.getApplicationsByEventId('event_1');

        expect(result, isEmpty);
      });
    });

    group('getTicketBalanceStatus', () {
      // happy path and null tests are above

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<List<dynamic>?>(
            'get_event_ticket_balance_status',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getTicketBalanceStatus('event_1'),
          throwsA(anything),
        );
      });
    });

    group('getApplicationsByEventId error', () {
      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_event_applications_with_user',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getApplicationsByEventId('event_1'),
          throwsA(anything),
        );
      });
    });

    group('getPersonalizedRecommendations', () {
      test('returns recommendations from RPC', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'get_personalized_recommendations',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<List<dynamic>>([
            {'event_id': 'event_1', 'score': 0.95},
            {'event_id': 'event_2', 'score': 0.87},
          ]),
        );

        final result = await repository.getPersonalizedRecommendations(
          userId: 'user_1',
        );

        expect(result, hasLength(2));
        expect(result.first['event_id'], 'event_1');
      });

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'get_personalized_recommendations',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getPersonalizedRecommendations(userId: 'user_1'),
          throwsA(anything),
        );
      });
    });

    group('getEventsWithinRadius', () {
      test('returns events within radius from RPC', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'get_events_within_radius',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<List<dynamic>>([
            {'event_id': 'event_1', 'distance': 500.0},
          ]),
        );

        final result = await repository.getEventsWithinRadius(
          latitude: 37.5665,
          longitude: 126.9780,
        );

        expect(result, hasLength(1));
        expect(result.first['distance'], 500.0);
      });

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'get_events_within_radius',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getEventsWithinRadius(
            latitude: 37.5665,
            longitude: 126.9780,
          ),
          throwsA(anything),
        );
      });
    });

    group('getBulkEligibilityData', () {
      test('returns eligibility data from RPC', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>>(
            'get_bulk_eligibility_data',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<Map<String, dynamic>>({
            'profile': {'name': '홍길동'},
            'is_verified': true,
          }),
        );

        final result = await repository.getBulkEligibilityData(
          userId: 'user_1',
        );

        expect(result['is_verified'], isTrue);
        expect((result['profile'] as Map)['name'], '홍길동');
      });

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>>(
            'get_bulk_eligibility_data',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getBulkEligibilityData(userId: 'user_1'),
          throwsA(anything),
        );
      });
    });

    // Fix #1941: active/ongoing events must appear in the user event feed
    group('getEventsByType', () {
      test(
        'returns active-status event in feed (regression for #1941)',
        () async {
          final activeEventJson = {
            ...eventJson,
            'id': 'event_active',
            'status': 'active',
          };
          unawaited(
            mockTable(mockClient, 'events', selectData: [activeEventJson]),
          );

          final result = await repository.getEventsByType(
            type: EventFeedType.newArrivals,
          );

          expect(result, hasLength(1));
          expect(result.first.id, 'event_active');
          expect(result.first.status, 'active');
        },
      );

      // Fix #1941 v2: ongoing events have start_time in the PAST — the original
      // gte('start_time', now) filter excluded them. Verify the query uses
      // gt('end_time') instead, which correctly includes ongoing events.
      test(
        'returns ongoing-status event with past start_time in feed (regression for #1941)',
        () async {
          final ongoingEventJson = {
            ...eventJson,
            'id': 'event_ongoing',
            'status': 'ongoing',
            // Ongoing events have already started — start_time is in the past
            'start_time': now
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
          };
          final builder = mockTable(
            mockClient,
            'events',
            selectData: [ongoingEventJson],
          );

          final result = await repository.getEventsByType(
            type: EventFeedType.closingSoon,
          );

          expect(result, hasLength(1));
          expect(result.first.status, 'ongoing');
          // Filter must use gt('end_time'), NOT gte('start_time') —
          // ongoing events have start_time <= now, so gte('start_time') would
          // incorrectly exclude them from the feed.
          expect(
            builder.recordedFilters.any(
              (f) => f.method == 'gt' && f.column == 'end_time',
            ),
            isTrue,
            reason: 'expected gt(end_time) filter to include ongoing events',
          );
          expect(
            builder.recordedFilters.any(
              (f) => f.method == 'gte' && f.column == 'start_time',
            ),
            isFalse,
            reason:
                'gte(start_time) must not be used — it excludes ongoing events',
          );
        },
      );
    });

    group('getEventsByPartnerId', () {
      test('returns events for partner', () async {
        unawaited(
          mockTable(mockClient, 'events', selectData: [eventJson]),
        );

        final result = await repository.getEventsByPartnerId('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_1');
      });

      test('returns empty list when no events', () async {
        unawaited(mockTable(mockClient, 'events', selectData: []));

        final result = await repository.getEventsByPartnerId('partner_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('error'),
          ),
        );

        await expectLater(
          repository.getEventsByPartnerId('partner_1'),
          throwsA(anything),
        );
      });

      // Fix #1941: active/ongoing events must appear in partner detail list
      test('returns active-status event (regression for #1941)', () async {
        final activeEventJson = {
          ...eventJson,
          'id': 'event_active',
          'status': 'active',
        };
        unawaited(
          mockTable(mockClient, 'events', selectData: [activeEventJson]),
        );

        final result = await repository.getEventsByPartnerId('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_active');
        expect(result.first.status, 'active');
      });

      // Fix #1941 v2: ongoing events have start_time in the PAST — verify
      // gt('end_time') is used so they are not excluded from the partner list.
      test(
        'returns ongoing-status event with past start_time (regression for #1941)',
        () async {
          final ongoingEventJson = {
            ...eventJson,
            'id': 'event_ongoing',
            'status': 'ongoing',
            // Ongoing events have already started — start_time is in the past
            'start_time': now
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
          };
          final builder = mockTable(
            mockClient,
            'events',
            selectData: [ongoingEventJson],
          );

          final result = await repository.getEventsByPartnerId('partner_1');

          expect(result, hasLength(1));
          expect(result.first.status, 'ongoing');
          // Filter must use gt('end_time') so ongoing events (start_time <= now)
          // are not excluded.
          expect(
            builder.recordedFilters.any(
              (f) => f.method == 'gt' && f.column == 'end_time',
            ),
            isTrue,
            reason: 'expected gt(end_time) filter to include ongoing events',
          );
          expect(
            builder.recordedFilters.any(
              (f) => f.method == 'gte' && f.column == 'start_time',
            ),
            isFalse,
            reason:
                'gte(start_time) must not be used — it excludes ongoing events',
          );
        },
      );
    });

    group('getTodayEvents', () {
      test('returns list of events for today', () async {
        unawaited(
          mockTable(mockClient, 'events', selectData: [eventJson]),
        );

        final result = await repository.getTodayEvents('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_1');
      });

      test('returns empty list when no events today', () async {
        unawaited(mockTable(mockClient, 'events', selectData: []));

        final result = await repository.getTodayEvents('partner_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('error'),
          ),
        );

        await expectLater(
          repository.getTodayEvents('partner_1'),
          throwsA(anything),
        );
      });
    });

    group('getUpcomingEvents', () {
      test('returns list of upcoming events', () async {
        unawaited(
          mockTable(mockClient, 'events', selectData: [eventJson]),
        );

        final result = await repository.getUpcomingEvents('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_1');
      });

      // Fix #1823: events transition to 'active' 30 min before start_time.
      // getUpcomingEvents must NOT exclude active events — they are legitimate
      // upcoming events that callers (checkin, dashboard) need to see.
      test('includes active-status events in results', () async {
        final activeEvent = Map<String, Object?>.from(eventJson)
          ..['status'] = 'active';
        unawaited(mockTable(mockClient, 'events', selectData: [activeEvent]));

        final result = await repository.getUpcomingEvents('partner_1');

        expect(result, hasLength(1));
        expect(result.first.status, 'active');
      });

      test('returns empty list when no upcoming events', () async {
        unawaited(mockTable(mockClient, 'events', selectData: []));

        final result = await repository.getUpcomingEvents('partner_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('error'),
          ),
        );

        await expectLater(
          repository.getUpcomingEvents('partner_1'),
          throwsA(anything),
        );
      });
    });

    group('getClosingSoonEvents', () {
      test('returns list of closing soon events', () async {
        unawaited(
          mockTable(mockClient, 'events', selectData: [eventJson]),
        );

        final result = await repository.getClosingSoonEvents('partner_1');

        expect(result, hasLength(1));
        expect(result.first.id, 'event_1');
      });

      test('returns empty list when no closing soon events', () async {
        unawaited(mockTable(mockClient, 'events', selectData: []));

        final result = await repository.getClosingSoonEvents('partner_1');

        expect(result, isEmpty);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('error'),
          ),
        );

        await expectLater(
          repository.getClosingSoonEvents('partner_1'),
          throwsA(anything),
        );
      });
    });

    group('getEntryGroupParticipantCounts', () {
      test('returns participant counts and target_capacity from RPC', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_entry_group_participant_counts',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeRpcBuilder<dynamic>(<Map<String, dynamic>>[
            {
              'entry_group_id': 'eg_1',
              'label': 'Group A',
              'participant_count': 5,
              'target_capacity': 10,
            },
            {
              'entry_group_id': 'eg_2',
              'label': 'Group B',
              'participant_count': 3,
              'target_capacity': 15,
            },
          ]),
        );

        final result = await repository.getEntryGroupParticipantCounts(
          'event_1',
        );

        expect(result, hasLength(2));
        expect(result.first['participant_count'], 5);
        expect(result.first['target_capacity'], 10);
        expect(result.last['target_capacity'], 15);
      });

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_entry_group_participant_counts',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.getEntryGroupParticipantCounts('event_1'),
          throwsA(anything),
        );
      });
    });

    group('getTodayActiveEventsForUser', () {
      Map<String, dynamic> makeEventWithParticipant({
        required String eventId,
        required DateTime startTime,
        required DateTime endTime,
        String participantStatus = 'ticket_issued',
        String eventStatus = 'scheduled',
      }) {
        return {
          'id': eventId,
          'party_id': 'party_1',
          'title': 'Test Event',
          'status': eventStatus,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'participant': [
            {'id': 'p_1', 'user_id': 'user_1', 'status': participantStatus},
          ],
        };
      }

      test('returns active events with participant status', () async {
        // Note: .order('start_time') is verified at the Supabase query level.
        // The mock returns insertion order, so data stays ascending here.
        final eventData = [
          makeEventWithParticipant(
            eventId: 'event_1',
            startTime: now.subtract(const Duration(hours: 1)),
            endTime: now.add(const Duration(hours: 2)),
            participantStatus: 'checked_in',
          ),
          makeEventWithParticipant(
            eventId: 'event_2',
            startTime: now,
            endTime: now.add(const Duration(hours: 3)),
          ),
        ];

        unawaited(
          mockTable(mockClient, 'events', selectData: eventData),
        );
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [
              {
                'event_id': 'event_1',
                'refund_status': null,
              },
            ],
          ),
        );

        final result = await repository.getTodayActiveEventsForUser('user_1');

        expect(result, hasLength(2));
        expect(result[0].event.id, 'event_1');
        expect(result[0].participantStatus, 'checked_in');
        expect(result[1].event.id, 'event_2');
        expect(result[1].participantStatus, 'ticket_issued');
      });

      test('excludes refunded events', () async {
        final eventData = [
          makeEventWithParticipant(
            eventId: 'event_1',
            startTime: now.subtract(const Duration(hours: 1)),
            endTime: now.add(const Duration(hours: 2)),
          ),
          makeEventWithParticipant(
            eventId: 'event_2',
            startTime: now,
            endTime: now.add(const Duration(hours: 3)),
          ),
        ];

        unawaited(
          mockTable(mockClient, 'events', selectData: eventData),
        );
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            selectData: [
              {'event_id': 'event_1', 'refund_status': 'refunded'},
              {'event_id': 'event_2', 'refund_status': null},
            ],
          ),
        );

        final result = await repository.getTodayActiveEventsForUser('user_1');

        expect(result, hasLength(1));
        expect(result.first.event.id, 'event_2');
      });

      test('returns empty list when no matching events', () async {
        unawaited(
          mockTable(mockClient, 'events', selectData: []),
        );

        final result = await repository.getTodayActiveEventsForUser('user_1');

        expect(result, isEmpty);
      });

      test(
        'defaults participantStatus to ticket_issued when missing',
        () async {
          final eventData = [
            {
              'id': 'event_1',
              'party_id': 'party_1',
              'title': 'Test Event',
              'status': 'scheduled',
              'start_time': now
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
              'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              'participant': <Map<String, dynamic>>[],
            },
          ];

          unawaited(
            mockTable(mockClient, 'events', selectData: eventData),
          );
          unawaited(
            mockTable(mockClient, 'event_applications', selectData: []),
          );

          final result = await repository.getTodayActiveEventsForUser('user_1');

          expect(result, hasLength(1));
          expect(result.first.participantStatus, 'ticket_issued');
        },
      );

      // Fix #1212: events that ended earlier today must still be returned so
      // the nowbar can show the "종료됨" state (e.g. match results accessible).
      test('returns already-ended event from today', () async {
        final startTime = DateTime(now.year, now.month, now.day, 10);
        final endTime = DateTime(now.year, now.month, now.day, 12);
        final eventsTable = mockTable(
          mockClient,
          'events',
          selectData: [
            makeEventWithParticipant(
              eventId: 'event_ended',
              startTime: startTime,
              endTime: endTime,
              eventStatus: 'completed',
            ),
          ],
        );
        final startOfDay = DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String();
        unawaited(
          mockTable(mockClient, 'event_applications', selectData: []),
        );

        final result = await repository.getTodayActiveEventsForUser('user_1');

        expect(result, hasLength(1));
        expect(result.first.event.id, 'event_ended');
        expect(result.first.event.status, 'completed');
        expect(
          eventsTable.recordedFilters,
          contains(
            predicate<RecordedFilterOperation>(
              (filter) =>
                  filter.method == 'gte' &&
                  filter.column == 'end_time' &&
                  filter.value == startOfDay,
            ),
          ),
        );
      });

      test('throws on database error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('DB error'),
          ),
        );

        await expectLater(
          repository.getTodayActiveEventsForUser('user_1'),
          throwsA(anything),
        );
      });
    });

    // Regression test for #1215: onboarding must not reappear after all
    // upcoming events end. getHasAnyEvents checks all-time, not just upcoming.
    group('getHasAnyEvents', () {
      test('returns true when partner has at least one event', () async {
        unawaited(
          mockTable(mockClient, 'events', countValue: 1),
        );

        final result = await repository.getHasAnyEvents('partner_1');

        expect(result, isTrue);
      });

      test('returns false when partner has no events', () async {
        unawaited(
          mockTable(mockClient, 'events'),
        );

        final result = await repository.getHasAnyEvents('partner_1');

        expect(result, isFalse);
      });

      test('rethrows on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'events',
            shouldThrow: Exception('DB error'),
          ),
        );

        // Rethrowing lets the controller decide what to show (error state),
        // preventing a DB hiccup from re-showing onboarding to existing partners.
        await expectLater(
          repository.getHasAnyEvents('partner_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    // Regression tests for #1534: searchEvents must return fully hydrated Event
    // models (party/tickets/location) — bare RPC rows caused '제목 없음'/'가격 미정'.
    group('searchEvents', () {
      final partyJson = {
        'id': 'party_1',
        'partner_id': 'partner_1',
        'title': '강남 파티',
        'status': 'active',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'location': {
          'id': 'loc_1',
          'partner_id': 'partner_1',
          'name': '강남역',
          'address': '서울 강남구',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      };

      final ticketJson = {
        'id': 'ticket_1',
        'event_id': 'event_1',
        'name': '일반 티켓',
        'price': 30000,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final eventWithRelationsJson = {
        ...eventJson,
        'party': partyJson,
        'entryGroups': <Map<String, dynamic>>[],
        'tickets': [ticketJson],
      };

      test('returns empty list for empty query without calling RPC', () async {
        final result = await repository.searchEvents('');

        expect(result, isEmpty);
        verifyNever(
          () => mockClient.rpc<List<dynamic>>(
            'search_events_pgroonga',
            params: any(named: 'params'),
          ),
        );
      });

      test(
        'returns empty list and skips events query when RPC returns no IDs',
        () async {
          when(
            () => mockClient.rpc<List<dynamic>>(
              'search_events_pgroonga',
              params: any(named: 'params'),
            ),
          ).thenAnswer((_) => FakeRpcBuilder<List<dynamic>>([]));

          final result = await repository.searchEvents('밍글릿');

          expect(result, isEmpty);
          verifyNever(() => mockClient.from('events'));
        },
      );

      test(
        'returns events with party, location, and ticket relations',
        () async {
          when(
            () => mockClient.rpc<List<dynamic>>(
              'search_events_pgroonga',
              params: any(named: 'params'),
            ),
          ).thenAnswer(
            (_) => FakeRpcBuilder<List<dynamic>>([
              {'id': 'event_1'},
            ]),
          );
          unawaited(
            mockTable(
              mockClient,
              'events',
              selectData: [eventWithRelationsJson],
            ),
          );

          final result = await repository.searchEvents('강남');

          expect(result, hasLength(1));
          expect(result.first.id, 'event_1');
          expect(result.first.party, isNotNull);
          expect(result.first.party!.title, '강남 파티');
          expect(result.first.party!.location, isNotNull);
          expect(result.first.party!.location!.name, '강남역');
          expect(result.first.tickets, isNotNull);
          expect(result.first.tickets, hasLength(1));
          expect(result.first.tickets!.first.id, 'ticket_1');
          expect(result.first.tickets!.first.price, 30000);
        },
      );

      test(
        'preserves PGroonga relevance order, not DB insertion order',
        () async {
          // RPC says event_2 is more relevant than event_1
          when(
            () => mockClient.rpc<List<dynamic>>(
              'search_events_pgroonga',
              params: any(named: 'params'),
            ),
          ).thenAnswer(
            (_) => FakeRpcBuilder<List<dynamic>>([
              {'id': 'event_2'},
              {'id': 'event_1'},
            ]),
          );
          // DB returns them in the opposite order
          final event2Json = {...eventJson, 'id': 'event_2', 'title': '홍대 이벤트'};
          unawaited(
            mockTable(
              mockClient,
              'events',
              selectData: [eventJson, event2Json],
            ),
          );

          final result = await repository.searchEvents('이벤트');

          expect(result, hasLength(2));
          // PGroonga order must be restored
          expect(result[0].id, 'event_2');
          expect(result[1].id, 'event_1');
        },
      );

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'search_events_pgroonga',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.searchEvents('밍글릿'),
          throwsA(anything),
        );
      });
    });

    group('getApplicationById', () {
      test('returns EventApplication when found', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            maybeSingleData: applicationJson,
          ),
        );

        final result = await repository.getApplicationById('app_1');

        expect(result, isNotNull);
        expect(result!.id, 'app_1');
        expect(result.status, 'confirmed');
      });

      test('returns null when not found', () async {
        unawaited(mockTable(mockClient, 'event_applications'));

        final result = await repository.getApplicationById('app_unknown');

        expect(result, isNull);
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('DB error'),
          ),
        );

        await expectLater(
          repository.getApplicationById('app_1'),
          throwsA(anything),
        );
      });
    });
  });
}
