import 'package:app_user/src/features/ticket/data/ticket_token_service.dart';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockTicketWalletRepository extends Mock implements TicketWalletRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class _FakeTicketToken extends Fake implements TicketToken {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTicketToken());
  });
  late MockTicketWalletRepository mockWallet;
  late MockSupabaseClient mockSupabase;
  late MockFunctionsClient mockFunctions;
  late TicketTokenService service;

  final expiredToken = TicketToken(
    ticketId: 'ticket_1',
    eventId: 'event_1',
    userId: 'user_1',
    signature: 'old_sig',
    expiresAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  final validToken = TicketToken(
    ticketId: 'ticket_1',
    eventId: 'event_1',
    userId: 'user_1',
    signature: 'valid_sig',
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  final fetchedTokenData = <String, dynamic>{
    'ticket_id': 'ticket_1',
    'event_id': 'event_1',
    'user_id': 'user_1',
    'signature': 'fetched_sig',
    'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
  };

  setUp(() {
    mockWallet = MockTicketWalletRepository();
    mockSupabase = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();

    when(() => mockSupabase.functions).thenReturn(mockFunctions);

    service = TicketTokenService(wallet: mockWallet, supabase: mockSupabase);
  });

  group('TicketTokenService', () {
    // Fix #1206: Returns cached token if in wallet and not expired
    test('returns cached token if in wallet and not expired', () async {
      when(() => mockWallet.getTicket('ticket_1')).thenAnswer((_) async => validToken);

      final result = await service.getToken('ticket_1');

      expect(result, isNotNull);
      expect(result?.signature, 'valid_sig');
      // Should not call Edge Function
      verifyNever(() => mockFunctions.invoke(any(), body: any(named: 'body')));
    });

    // Fix #1206: Fetches from Edge Function if not in wallet; saves to wallet
    test('fetches from Edge Function if not in wallet; saves to wallet', () async {
      when(() => mockWallet.getTicket('ticket_1')).thenAnswer((_) async => null);
      when(() => mockWallet.saveTicket(any())).thenAnswer((_) async {});
      when(
        () => mockFunctions.invoke(
          'user-get-ticket-token',
          body: {'ticket_id': 'ticket_1'},
        ),
      ).thenAnswer((_) async => FunctionResponse(status: 200, data: fetchedTokenData));

      final result = await service.getToken('ticket_1');

      expect(result, isNotNull);
      expect(result?.signature, 'fetched_sig');
      verify(() => mockWallet.saveTicket(any())).called(1);
    });

    // Fix #1206: Re-fetches if cached token is expired
    test('re-fetches from Edge Function if cached token is expired', () async {
      when(() => mockWallet.getTicket('ticket_1')).thenAnswer((_) async => expiredToken);
      when(() => mockWallet.saveTicket(any())).thenAnswer((_) async {});
      when(
        () => mockFunctions.invoke(
          'user-get-ticket-token',
          body: {'ticket_id': 'ticket_1'},
        ),
      ).thenAnswer((_) async => FunctionResponse(status: 200, data: fetchedTokenData));

      final result = await service.getToken('ticket_1');

      expect(result, isNotNull);
      expect(result?.signature, 'fetched_sig');
      verify(() => mockFunctions.invoke(any(), body: any(named: 'body'))).called(1);
    });

    // Fix #1206: Returns null if Edge Function returns error
    test('returns null if Edge Function returns non-200 status', () async {
      when(() => mockWallet.getTicket('ticket_1')).thenAnswer((_) async => null);
      when(
        () => mockFunctions.invoke(
          'user-get-ticket-token',
          body: {'ticket_id': 'ticket_1'},
        ),
      ).thenAnswer((_) async => FunctionResponse(status: 404, data: {'error': 'Ticket not found'}));

      final result = await service.getToken('ticket_1');

      expect(result, isNull);
      verifyNever(() => mockWallet.saveTicket(any()));
    });

    test('returns null if Edge Function throws an exception', () async {
      when(() => mockWallet.getTicket('ticket_1')).thenAnswer((_) async => null);
      when(
        () => mockFunctions.invoke(
          'user-get-ticket-token',
          body: {'ticket_id': 'ticket_1'},
        ),
      ).thenThrow(Exception('network error'));

      final result = await service.getToken('ticket_1');

      expect(result, isNull);
    });
  });
}
