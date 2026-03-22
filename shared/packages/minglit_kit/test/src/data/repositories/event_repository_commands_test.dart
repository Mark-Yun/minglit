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
  late MockFunctionsClient mockFunctions;

  final now = DateTime.now();
  final mockUser = MockUser();

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
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = EventRepository(supabase: mockClient);
  });

  group('EventRepository Commands', () {
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
      test('calls payment-verify edge function', () async {
        when(
          () => mockFunctions.invoke(
            'payment-verify',
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

        verify(
          () => mockFunctions.invoke(
            'payment-verify',
            body: {'imp_uid': 'imp_123', 'merchant_uid': 'order_456'},
          ),
        ).called(1);
      });

      test('throws on edge function error', () async {
        when(
          () => mockFunctions.invoke(
            'payment-verify',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        await expectLater(
          repository.confirmPayment(
            impUid: 'imp_123',
            merchantUid: 'order_456',
          ),
          throwsA(anything),
        );
      });
    });

    group('cancelPayment', () {
      test('succeeds with 200 response', () async {
        when(
          () => mockFunctions.invoke(
            'payment-cancel',
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

      test('succeeds without reason', () async {
        when(
          () => mockFunctions.invoke(
            'payment-cancel',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.cancelPayment(
            paymentId: 'pay_123',
            refundAmount: 30000,
          ),
          completes,
        );
      });

      test('throws MinglitUserException when non-200', () async {
        when(
          () => mockFunctions.invoke(
            'payment-cancel',
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

    group('applyEvent', () {
      test('calls apply_event RPC and returns application ID', () async {
        when(
          () => mockClient.rpc<String>(
            'apply_event',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<String>('app_new_1'));

        final result = await repository.applyEvent(
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          paymentId: 'pay_123',
          paymentAmount: 30000,
        );

        expect(result, 'app_new_1');
      });

      test('passes verification data when provided', () async {
        final verificationData = {
          'partner_id': 'partner_1',
          'verification_id': 'v_1',
          'data': {'field': 'value'},
        };

        when(
          () => mockClient.rpc<String>(
            'apply_event',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<String>('app_new_2'));

        final result = await repository.applyEvent(
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          paymentId: 'pay_123',
          paymentAmount: 30000,
          verificationData: verificationData,
        );

        expect(result, 'app_new_2');
      });

      test('throws on RPC error', () async {
        when(
          () => mockClient.rpc<String>(
            'apply_event',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.applyEvent(
            eventId: 'event_1',
            ticketId: 'ticket_1',
            userId: 'user_1',
            paymentId: 'pay_123',
            paymentAmount: 30000,
          ),
          throwsA(anything),
        );
      });
    });

    group('createOrderViaEF', () {
      test('returns CreateOrderResult on success', () async {
        when(
          () => mockFunctions.invoke(
            'user-create-order',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'application_id': 'app-ef-1',
              'amount': 15000,
              'requires_payment': true,
              'ticket_name': '일반 티켓',
            },
          ),
        );

        final result = await repository.createOrderViaEF(
          eventId: 'event_1',
          ticketId: 'ticket_1',
        );

        expect(result.applicationId, 'app-ef-1');
        expect(result.amount, 15000);
        expect(result.requiresPayment, true);
        expect(result.ticketName, '일반 티켓');
      });

      test('returns free order result', () async {
        when(
          () => mockFunctions.invoke(
            'user-create-order',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'application_id': 'app-ef-2',
              'amount': 0,
              'requires_payment': false,
              'ticket_name': '무료 티켓',
            },
          ),
        );

        final result = await repository.createOrderViaEF(
          eventId: 'event_1',
          ticketId: 'ticket_free',
        );

        expect(result.amount, 0);
        expect(result.requiresPayment, false);
      });

      test('passes verification data when provided', () async {
        when(
          () => mockFunctions.invoke(
            'user-create-order',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {
              'success': true,
              'application_id': 'app-ef-3',
              'amount': 15000,
              'requires_payment': true,
              'ticket_name': '일반 티켓',
            },
          ),
        );

        await repository.createOrderViaEF(
          eventId: 'event_1',
          ticketId: 'ticket_1',
          verificationData: {
            'verification_id': 'v_1',
            'data': {'field': 'value'},
          },
        );

        verify(
          () => mockFunctions.invoke(
            'user-create-order',
            body: {
              'event_id': 'event_1',
              'ticket_id': 'ticket_1',
              'verification_data': {
                'verification_id': 'v_1',
                'data': {'field': 'value'},
              },
            },
          ),
        ).called(1);
      });

      test('throws MinglitUserException on error response', () async {
        when(
          () => mockFunctions.invoke(
            'user-create-order',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: {'error': '티켓이 매진되었습니다.'},
          ),
        );

        expect(
          () => repository.createOrderViaEF(
            eventId: 'event_1',
            ticketId: 'ticket_1',
          ),
          throwsA(isA<MinglitUserException>()),
        );
      });

      test('throws on network error', () async {
        when(
          () => mockFunctions.invoke(
            'user-create-order',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        await expectLater(
          repository.createOrderViaEF(
            eventId: 'event_1',
            ticketId: 'ticket_1',
          ),
          throwsA(anything),
        );
      });
    });

    group('createOrder', () {
      test('creates new application when none exists', () async {
        // getApplication returns null (no existing application)
        unawaited(
          mockTable(mockClient, 'event_applications'),
        );

        when(
          () => mockClient.rpc<String>(
            'apply_event',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => FakeRpcBuilder<String>('app_new_1'));

        final result = await repository.createOrder(
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          amount: 30000,
        );

        expect(result, 'app_new_1');
      });

      test('updates existing application when one exists', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            maybeSingleData: applicationJson,
          ),
        );
        unawaited(mockTable(mockClient, 'verification_submissions'));

        final result = await repository.createOrder(
          eventId: 'event_1',
          ticketId: 'ticket_1',
          userId: 'user_1',
          amount: 30000,
        );

        expect(result, 'app_1');
      });

      test('throws when getApplication fails', () async {
        unawaited(
          mockTable(
            mockClient,
            'event_applications',
            shouldThrow: Exception('db error'),
          ),
        );

        await expectLater(
          repository.createOrder(
            eventId: 'event_1',
            ticketId: 'ticket_1',
            userId: 'user_1',
            amount: 30000,
          ),
          throwsA(anything),
        );
      });

      test('throws when applyEvent RPC fails for new application', () async {
        unawaited(mockTable(mockClient, 'event_applications'));

        when(
          () => mockClient.rpc<String>(
            'apply_event',
            params: any(named: 'params'),
          ),
        ).thenThrow(Exception('RPC error'));

        await expectLater(
          repository.createOrder(
            eventId: 'event_1',
            ticketId: 'ticket_1',
            userId: 'user_1',
            amount: 30000,
          ),
          throwsA(anything),
        );
      });
    });
  });
}
