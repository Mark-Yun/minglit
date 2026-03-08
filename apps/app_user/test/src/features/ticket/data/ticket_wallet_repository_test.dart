import 'dart:convert';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_data.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late TicketWalletRepository repository;

  final testToken = TicketToken(
    ticketId: 'ticket_1',
    eventId: 'event_1',
    userId: 'user_1',
    signature: 'signed_data',
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );

  setUp(() {
    mockStorage = MockSecureStorage();
    repository = TicketWalletRepository(mockStorage);
  });

  group('TicketWalletRepository', () {
    test('saveTicket stores token as JSON string', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});

      await repository.saveTicket(testToken);

      verify(
        () => mockStorage.write(
          key: 'ticket_ticket_1',
          value: any(named: 'value', that: contains('signed_data')),
        ),
      ).called(1);
    });

    test('getTicket returns token when exists', () async {
      when(
        () => mockStorage.read(key: 'ticket_ticket_1'),
      ).thenAnswer((_) async => jsonEncode(testToken.toJson()));

      final result = await repository.getTicket('ticket_1');

      expect(result, isNotNull);
      expect(result?.ticketId, 'ticket_1');
      expect(result?.signature, 'signed_data');
    });

    test('getTicket returns null when not exists', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final result = await repository.getTicket('non_existent');

      expect(result, isNull);
    });

    test('deleteTicket removes token from storage', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async => {});

      await repository.deleteTicket('ticket_1');

      verify(() => mockStorage.delete(key: 'ticket_ticket_1')).called(1);
    });
  });
}
