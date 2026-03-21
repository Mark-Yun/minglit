import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    group('getPendingApplicationCount', () {
      test('returns pending count', () async {
        unawaited(
          mockTable(
            mockClient,
            'verification_submissions',
            selectData: [
              {'id': 'sub_1'},
              {'id': 'sub_2'},
            ],
            countValue: 2,
          ),
        );

        final result =
            await repository.getPendingApplicationCount('partner_1');

        expect(result, 2);
      });

      test('returns 0 when no pending submissions', () async {
        unawaited(
          mockTable(
            mockClient,
            'verification_submissions',
            countValue: 0,
          ),
        );

        final result =
            await repository.getPendingApplicationCount('partner_1');

        expect(result, 0);
      });

      test('returns 0 on error (fail-safe)', () async {
        unawaited(
          mockTable(
            mockClient,
            'verification_submissions',
            shouldThrow: Exception('db error'),
          ),
        );

        final result =
            await repository.getPendingApplicationCount('partner_1');

        expect(result, 0);
      });
    });

    group('getTicketBalanceStatus', () {
      test('returns ticket balance map', () async {
        when(
          () => mockClient.rpc<List<dynamic>?>(
            'get_event_ticket_balance_status',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) =>
          FakeRpcBuilder<List<dynamic>?>([
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
        ).thenAnswer((_) =>
          FakeRpcBuilder<dynamic>([
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

        final result =
            await repository.getApplicationsByEventId('event_1');

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

        final result =
            await repository.getApplicationsByEventId('event_1');

        expect(result, isEmpty);
      });
    });

    group('getPersonalizedRecommendations', () {
      test('returns recommendations from RPC', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'get_personalized_recommendations',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) =>
          FakeRpcBuilder<List<dynamic>>([
            {'event_id': 'event_1', 'score': 0.95},
            {'event_id': 'event_2', 'score': 0.87},
          ]),
        );

        final result = await repository.getPersonalizedRecommendations(
          userId: 'user_1',
          limit: 10,
        );

        expect(result, hasLength(2));
        expect(result.first['event_id'], 'event_1');
      });
    });

    group('getEventsWithinRadius', () {
      test('returns events within radius from RPC', () async {
        when(
          () => mockClient.rpc<List<dynamic>>(
            'get_events_within_radius',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) =>
          FakeRpcBuilder<List<dynamic>>([
            {'event_id': 'event_1', 'distance': 500.0},
          ]),
        );

        final result = await repository.getEventsWithinRadius(
          latitude: 37.5665,
          longitude: 126.9780,
          radiusMeters: 5000,
        );

        expect(result, hasLength(1));
        expect(result.first['distance'], 500.0);
      });
    });

    group('getBulkEligibilityData', () {
      test('returns eligibility data from RPC', () async {
        when(
          () => mockClient.rpc<Map<String, dynamic>>(
            'get_bulk_eligibility_data',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) =>
          FakeRpcBuilder<Map<String, dynamic>>({
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
      test('returns participant counts from RPC', () async {
        when(
          () => mockClient.rpc<dynamic>(
            'get_entry_group_participant_counts',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) =>
          FakeRpcBuilder<dynamic>(<Map<String, dynamic>>[
            {'entry_group_id': 'eg_1', 'count': 5},
            {'entry_group_id': 'eg_2', 'count': 3},
          ]),
        );

        final result =
            await repository.getEntryGroupParticipantCounts('event_1');

        expect(result, hasLength(2));
        expect(result.first['count'], 5);
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
  });
}
