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

    // Fix #1409: 비-200 응답 시 response.data가 null → cast crash 재발 방지
    test(
      'throws MinglitUserException on non-200 response with null data',
      () async {
        when(
          () => mockFunctions.invoke(
            'apply-event',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 409),
        );

        await expectLater(
          repository.applyEvent(eventId: 'event_1', ticketId: 'ticket_1'),
          throwsA(isA<MinglitUserException>()),
        );
      },
    );

    test(
      'throws MinglitUserException on non-200 response with error message',
      () async {
        when(
          () => mockFunctions.invoke(
            'apply-event',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 409,
            data: {'error': '이미 신청한 이벤트입니다.'},
          ),
        );

        await expectLater(
          repository.applyEvent(eventId: 'event_1', ticketId: 'ticket_1'),
          throwsA(
            isA<MinglitUserException>().having(
              (e) => e.message,
              'message',
              '이미 신청한 이벤트입니다.',
            ),
          ),
        );
      },
    );
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

  // Fix #1945: confirmPayment must throw on non-200 (functions.invoke never throws for HTTP errors)
  group('EventRepository.confirmPayment', () {
    test('completes without error on 200 response', () async {
      when(
        () => mockFunctions.invoke(
          'payment-verify',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'verified': true}),
      );

      await expectLater(
        repository.confirmPayment(
          impUid: 'imp_123',
          merchantUid: 'merchant_123',
        ),
        completes,
      );
    });

    test('throws MinglitUserException on non-200 with error message', () async {
      when(
        () => mockFunctions.invoke(
          'payment-verify',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 400,
          data: {'error': '결제 정보가 일치하지 않습니다.'},
        ),
      );

      await expectLater(
        repository.confirmPayment(
          impUid: 'imp_bad',
          merchantUid: 'merchant_bad',
        ),
        throwsA(
          isA<MinglitUserException>().having(
            (e) => e.message,
            'message',
            '결제 정보가 일치하지 않습니다.',
          ),
        ),
      );
    });

    test('throws MinglitUserException on 500 with fallback message', () async {
      when(
        () => mockFunctions.invoke(
          'payment-verify',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => FunctionResponse(status: 500));

      await expectLater(
        repository.confirmPayment(
          impUid: 'imp_err',
          merchantUid: 'merchant_err',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });
  });

  // Fix #1945: approveApplication must throw on non-200
  group('EventRepository.approveApplication', () {
    test('completes without error on 200 response', () async {
      when(
        () => mockFunctions.invoke(
          'partner-approve-application',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'approved': true}),
      );

      await expectLater(
        repository.approveApplication(applicationId: 'app_1'),
        completes,
      );
    });

    test('throws MinglitUserException on non-200', () async {
      when(
        () => mockFunctions.invoke(
          'partner-approve-application',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 409,
          data: {'error': '이미 처리된 신청입니다.'},
        ),
      );

      await expectLater(
        repository.approveApplication(applicationId: 'app_1'),
        throwsA(
          isA<MinglitUserException>().having(
            (e) => e.message,
            'message',
            '이미 처리된 신청입니다.',
          ),
        ),
      );
    });
  });

  // Fix #1945: rejectApplication must throw on non-200
  group('EventRepository.rejectApplication', () {
    test('completes without error on 200 response', () async {
      when(
        () => mockFunctions.invoke(
          'partner-reject-application',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'rejected': true}),
      );

      await expectLater(
        repository.rejectApplication(
          applicationId: 'app_1',
          reason: '조건 불충족',
        ),
        completes,
      );
    });

    test('throws MinglitUserException on non-200', () async {
      when(
        () => mockFunctions.invoke(
          'partner-reject-application',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 500,
          data: {'error': '서버 오류'},
        ),
      );

      await expectLater(
        repository.rejectApplication(
          applicationId: 'app_1',
          reason: '조건 불충족',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });
  });

  // Fix #1945: bulkApproveApplications must throw on non-200
  group('EventRepository.bulkApproveApplications', () {
    test('completes without error on 200 response', () async {
      when(
        () => mockFunctions.invoke(
          'partner-approve-application',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: {'approved': 5}),
      );

      await expectLater(
        repository.bulkApproveApplications(eventId: 'event_1'),
        completes,
      );
    });

    test('throws MinglitUserException on non-200', () async {
      when(
        () => mockFunctions.invoke(
          'partner-approve-application',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 500,
          data: {'error': '일괄 승인 실패'},
        ),
      );

      await expectLater(
        repository.bulkApproveApplications(eventId: 'event_1'),
        throwsA(
          isA<MinglitUserException>().having(
            (e) => e.message,
            'message',
            '일괄 승인 실패',
          ),
        ),
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
