import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/checkin_repository.dart';
import 'package:minglit_kit/src/utils/ticket_crypto.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late CheckinRepository repository;
  late TicketCrypto crypto;
  late SimpleKeyPair keyPair;
  late SimplePublicKey publicKey;
  late MockSupabaseClient mockClient;

  setUpAll(() async {
    crypto = TicketCrypto();
    keyPair = await crypto.generateKeyPair();
    publicKey = await keyPair.extractPublicKey();
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = CheckinRepository(
      crypto: crypto,
      supabase: mockClient,
    );
  });

  group('CheckinRepository', () {
    group('mintTicket', () {
      test('returns a valid TicketToken with correct fields', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        expect(token.ticketId, 'ticket_1');
        expect(token.eventId, 'event_1');
        expect(token.userId, 'user_1');
        expect(token.signature, isNotEmpty);
        expect(token.expiresAt.isAfter(DateTime.now()), isTrue);
      });

      test('generates different signatures for different payloads', () async {
        final token1 = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        final token2 = await repository.mintTicket(
          ticketId: 'ticket_2',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        expect(token1.signature, isNot(equals(token2.signature)));
      });
    });

    group('verifyAndCheckin', () {
      // Fix #1810: verifyAndCheckin은 서명 검증 후 process_qr_checkin RPC를 호출한다.
      // 서명/만료 검사는 클라이언트에서, DB 업데이트는 RPC에서 원자적으로 처리.

      test('returns false for tampered signature (before RPC call)', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        final otherToken = await repository.mintTicket(
          ticketId: 'ticket_OTHER',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        final tamperedToken = token.copyWith(signature: otherToken.signature);

        // Invalid signature → returns false immediately without calling RPC
        final result = await repository.verifyAndCheckin(
          token: tamperedToken,
          serverPublicKey: publicKey,
        );

        expect(result, isFalse);
        verifyNever(() => mockClient.rpc<dynamic>(any(), params: any(named: 'params')));
      });

      test('returns false for wrong public key (before RPC call)', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        final otherKeyPair = await crypto.generateKeyPair();
        final otherPublicKey = await otherKeyPair.extractPublicKey();

        final result = await repository.verifyAndCheckin(
          token: token,
          serverPublicKey: otherPublicKey,
        );

        expect(result, isFalse);
        verifyNever(() => mockClient.rpc<dynamic>(any(), params: any(named: 'params')));
      });

      test('calls process_qr_checkin RPC and returns true on success', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket-uuid-1',
          eventId: 'event-uuid-1',
          userId: 'user-uuid-1',
          serverPrivateKey: keyPair,
        );

        when(
          () => mockClient.rpc<String>(
            'process_qr_checkin',
            params: {
              'p_ticket_id': token.ticketId,
              'p_event_id': token.eventId,
              'p_user_id': token.userId,
            },
          ),
        ).thenAnswer((_) async => 'success');

        final result = await repository.verifyAndCheckin(
          token: token,
          serverPublicKey: publicKey,
        );

        expect(result, isTrue);
        verify(
          () => mockClient.rpc<String>(
            'process_qr_checkin',
            params: {
              'p_ticket_id': token.ticketId,
              'p_event_id': token.eventId,
              'p_user_id': token.userId,
            },
          ),
        ).called(1);
      });

      test('returns false when RPC returns already_checked_in', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket-uuid-1',
          eventId: 'event-uuid-1',
          userId: 'user-uuid-1',
          serverPrivateKey: keyPair,
        );

        when(
          () => mockClient.rpc<String>(
            'process_qr_checkin',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) async => 'already_checked_in');

        final result = await repository.verifyAndCheckin(
          token: token,
          serverPublicKey: publicKey,
        );

        expect(result, isFalse);
      });

      test('throws StateError when RPC returns not_found', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket-uuid-1',
          eventId: 'event-uuid-1',
          userId: 'user-uuid-1',
          serverPrivateKey: keyPair,
        );

        when(
          () => mockClient.rpc<String>(
            'process_qr_checkin',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) async => 'not_found');

        expect(
          () => repository.verifyAndCheckin(token: token, serverPublicKey: publicKey),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
