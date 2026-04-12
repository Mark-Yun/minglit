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

  setUp(() {
    mockClient = createMockSupabase();
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = EventRepository(supabase: mockClient);
  });

  group('EventRepository.applyEvent', () {
    test('returns FreeApplyEventResult for free ticket response', () async {
      when(
        () => mockFunctions.invoke(
          'apply-event',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {
            'type': 'free',
            'application_id': 'app_free_1',
          },
        ),
      );

      final result = await repository.applyEvent(
        eventId: 'event_1',
        ticketId: 'ticket_1',
      );

      expect(result, isA<FreeApplyEventResult>());
      expect(result.applicationId, 'app_free_1');
    });

    test('returns PaidApplyEventResult for paid ticket response', () async {
      when(
        () => mockFunctions.invoke(
          'apply-event',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {
            'type': 'paid',
            'application_id': 'app_paid_1',
            'order_id': 'order_123',
            'payment_amount': 30000,
          },
        ),
      );

      final result = await repository.applyEvent(
        eventId: 'event_1',
        ticketId: 'ticket_paid_1',
      );

      expect(result, isA<PaidApplyEventResult>());
      expect(result.applicationId, 'app_paid_1');
      final paidResult = result as PaidApplyEventResult;
      expect(paidResult.orderId, 'order_123');
      expect(paidResult.paymentAmount, 30000);
    });

    test('includes verification_data in request body when provided', () async {
      final verificationData = {
        'partner_id': 'partner_1',
        'verification_id': 'verif_career',
        'data': {'career': 'developer'},
      };

      when(
        () => mockFunctions.invoke(
          'apply-event',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {
            'type': 'free',
            'application_id': 'app_verif_1',
          },
        ),
      );

      final result = await repository.applyEvent(
        eventId: 'event_1',
        ticketId: 'ticket_1',
        verificationData: verificationData,
      );

      expect(result.applicationId, 'app_verif_1');

      final captured =
          verify(
                () => mockFunctions.invoke(
                  'apply-event',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['verification_data'], verificationData);
    });

    test('omits verification_data from request body when null', () async {
      when(
        () => mockFunctions.invoke(
          'apply-event',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: {
            'type': 'free',
            'application_id': 'app_no_verif',
          },
        ),
      );

      await repository.applyEvent(
        eventId: 'event_1',
        ticketId: 'ticket_1',
      );

      final captured =
          verify(
                () => mockFunctions.invoke(
                  'apply-event',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured.containsKey('verification_data'), isFalse);
    });

    test('rethrows on Edge Function error', () async {
      when(
        () => mockFunctions.invoke(
          'apply-event',
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('EF error'));

      await expectLater(
        repository.applyEvent(
          eventId: 'event_1',
          ticketId: 'ticket_1',
        ),
        throwsA(anything),
      );
    });
  });

  group('EventRepository.cancelPayment', () {
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

  group('EventRepository.deleteApplication', () {
    test('completes without error', () async {
      mockTable(mockClient, 'event_applications');

      await expectLater(
        repository.deleteApplication(
          eventId: 'event_1',
          userId: 'user_1',
        ),
        completes,
      );
    });

    test('rethrows on error', () async {
      mockTable(
        mockClient,
        'event_applications',
        shouldThrow: Exception('delete error'),
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
}
