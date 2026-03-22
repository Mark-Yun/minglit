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
  late MockUser mockUser;

  setUp(() {
    mockClient = createMockSupabase();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user-1');
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = EventRepository(supabase: mockClient);
  });

  group('createOrder', () {
    test('returns CreateOrderResult on success (paid)', () async {
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
            'application_id': 'app-123',
            'amount': 15000,
            'requires_payment': true,
            'ticket_name': '남성 티켓',
          },
        ),
      );

      final result = await repository.createOrder(
        eventId: 'event-1',
        ticketId: 'ticket-1',
      );

      expect(result.applicationId, 'app-123');
      expect(result.amount, 15000);
      expect(result.requiresPayment, isTrue);
      expect(result.ticketName, '남성 티켓');
    });

    test('returns CreateOrderResult on success (free)', () async {
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
            'application_id': 'app-free',
            'amount': 0,
            'requires_payment': false,
            'ticket_name': '무료 티켓',
          },
        ),
      );

      final result = await repository.createOrder(
        eventId: 'event-2',
        ticketId: 'ticket-free',
      );

      expect(result.requiresPayment, isFalse);
      expect(result.amount, 0);
    });

    test('throws MinglitUserException on ALREADY_APPLIED error', () async {
      when(
        () => mockFunctions.invoke(
          'user-create-order',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 409,
          data: {'error': 'ALREADY_APPLIED'},
        ),
      );

      expect(
        () => repository.createOrder(
          eventId: 'event-1',
          ticketId: 'ticket-1',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });

    test('throws MinglitUserException on TICKET_SOLD_OUT error', () async {
      when(
        () => mockFunctions.invoke(
          'user-create-order',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 400,
          data: {'error': 'TICKET_SOLD_OUT'},
        ),
      );

      expect(
        () => repository.createOrder(
          eventId: 'event-1',
          ticketId: 'ticket-1',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });

    test('throws MinglitUserException on EVENT_NOT_FOUND error', () async {
      when(
        () => mockFunctions.invoke(
          'user-create-order',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 404,
          data: {'error': 'EVENT_NOT_FOUND'},
        ),
      );

      expect(
        () => repository.createOrder(
          eventId: 'bad-event',
          ticketId: 'ticket-1',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });

    test('throws MinglitUserException on ELIGIBILITY_FAILED error', () async {
      when(
        () => mockFunctions.invoke(
          'user-create-order',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 400,
          data: {
            'error': 'ELIGIBILITY_FAILED',
            'details': {'reason': 'gender_mismatch'},
          },
        ),
      );

      expect(
        () => repository.createOrder(
          eventId: 'event-1',
          ticketId: 'ticket-1',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });

    test('throws MinglitUserException when data is null', () async {
      when(
        () => mockFunctions.invoke(
          'user-create-order',
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200),
      );

      expect(
        () => repository.createOrder(
          eventId: 'event-1',
          ticketId: 'ticket-1',
        ),
        throwsA(isA<MinglitUserException>()),
      );
    });

    test('rethrows on network error', () async {
      when(
        () => mockFunctions.invoke(
          'user-create-order',
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () => repository.createOrder(
          eventId: 'event-1',
          ticketId: 'ticket-1',
        ),
        throwsA(anything),
      );
    });
  });
}
