import 'dart:async' show unawaited;
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
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

  late MockFunctionsClient mockFunctions;

  setUp(() {
    mockClient = createMockSupabase(currentUser: mockUser);
    when(() => mockUser.id).thenReturn('user_1');
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = EventRepository(supabase: mockClient);
  });

  group('EventRepository', () {
    group('getEventById', () {
      test('returns event with relations', () async {
        unawaited(mockTable(mockClient, 'events', singleData: eventJson));

        final result = await repository.getEventById('event_1');

        expect(result.id, 'event_1');
        expect(result.title, '강남 밍글릿 이벤트');
        expect(result.status, 'scheduled');
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
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
          ),
        );

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
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
          ),
        );

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

    group('deleteApplication', () {
      test('completes without error', () async {
        unawaited(mockTable(mockClient, 'event_applications'));

        await expectLater(
          repository.deleteApplication(
            eventId: 'event_1',
            userId: 'user_1',
          ),
          completes,
        );
      });

      test('throws on error', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('delete error'),
          ),
        );

        await expectLater(
          repository.deleteApplication(
            eventId: 'event_1',
            userId: 'user_1',
          ),
          throwsA(anything),
        );
      });
    });

    group('confirmPayment', () {
      test('calls edge function', () async {
        when(
          () => mockFunctions.invoke(
            'verify-payment-v1',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.confirmPayment(
            impUid: 'imp_123',
            merchantUid: 'order_456',
          ),
          completes,
        );
      });
    });

    group('cancelPayment', () {
      test('succeeds with 200 response', () async {
        when(
          () => mockFunctions.invoke(
            'cancel-payment',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.cancelPayment(
            paymentId: 'pay_123',
            refundAmount: 30000,
            reason: '고객 요청',
          ),
          completes,
        );
      });

      test('throws MinglitUserException when non-200', () async {
        when(
          () => mockFunctions.invoke(
            'cancel-payment',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 400, data: 'fail'),
        );

        expect(
          () => repository.cancelPayment(
            paymentId: 'pay_123',
            refundAmount: 30000,
          ),
          throwsA(isA<MinglitUserException>()),
        );
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

        final result = await repository.getPendingApplicationCount('partner_1');
        expect(result, 2);
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
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
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
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
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
          mockTable(mockClient, 'events', shouldThrow: Exception('error')),
        );

        await expectLater(
          repository.getClosingSoonEvents('partner_1'),
          throwsA(anything),
        );
      });
    });
  });
}
