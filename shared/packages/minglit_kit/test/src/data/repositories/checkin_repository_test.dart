import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/checkin_repository.dart';
import 'package:minglit_kit/src/utils/ticket_crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal [SupabaseClient] for unit tests that don't hit the network.
SupabaseClient _stubSupabase() =>
    SupabaseClient('https://stub.supabase.co', 'stub-anon-key');

void main() {
  late CheckinRepository repository;
  late TicketCrypto crypto;
  late SimpleKeyPair keyPair;
  late SimplePublicKey publicKey;

  setUpAll(() async {
    crypto = TicketCrypto();
    keyPair = await crypto.generateKeyPair();
    publicKey = await keyPair.extractPublicKey();
  });

  setUp(() {
    repository = CheckinRepository(
      crypto: crypto,
      supabase: _stubSupabase(),
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
      test('returns true for valid token', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        final result = await repository.verifyAndCheckin(
          token: token,
          serverPublicKey: publicKey,
        );

        expect(result, isTrue);
      });

      test('returns false for tampered signature', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        // Create tampered token with different signature
        final otherToken = await repository.mintTicket(
          ticketId: 'ticket_OTHER',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        // Use original token's data but other's signature
        final tamperedToken = token.copyWith(signature: otherToken.signature);

        final result = await repository.verifyAndCheckin(
          token: tamperedToken,
          serverPublicKey: publicKey,
        );

        expect(result, isFalse);
      });

      test('returns false for wrong public key', () async {
        final token = await repository.mintTicket(
          ticketId: 'ticket_1',
          eventId: 'event_1',
          userId: 'user_1',
          serverPrivateKey: keyPair,
        );

        // Generate a different key pair
        final otherKeyPair = await crypto.generateKeyPair();
        final otherPublicKey = await otherKeyPair.extractPublicKey();

        final result = await repository.verifyAndCheckin(
          token: token,
          serverPublicKey: otherPublicKey,
        );

        expect(result, isFalse);
      });
    });
  });
}
