import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/ticket_crypto.dart';

void main() {
  group('TicketCrypto', () {
    test('should sign and verify ticket data correctly', () async {
      final crypto = TicketCrypto();
      final keyPair = await crypto.generateKeyPair();

      const ticketId = 'ticket_123';
      const eventId = 'event_456';
      final payload = jsonEncode({
        'tid': ticketId,
        'eid': eventId,
        'exp': DateTime.now()
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch,
      });

      // 1. Sign
      final signature = await crypto.sign(payload, keyPair);

      // 2. Verify
      final publicKey = await keyPair.extractPublicKey();
      final isValid = await crypto.verify(payload, signature, publicKey);

      expect(isValid, isTrue);
    });

    test('should fail verification with wrong payload', () async {
      final crypto = TicketCrypto();
      final keyPair = await crypto.generateKeyPair();

      const payload = 'correct_payload';
      const tamperedPayload = 'tampered_payload';

      final signature = await crypto.sign(payload, keyPair);
      final publicKey = await keyPair.extractPublicKey();
      final isValid = await crypto.verify(
        tamperedPayload,
        signature,
        publicKey,
      );

      expect(isValid, isFalse);
    });

    test('should fail verification with wrong signature', () async {
      final crypto = TicketCrypto();
      final keyPair = await crypto.generateKeyPair();
      final otherKeyPair = await crypto.generateKeyPair();

      const payload = 'payload';

      final signature = await crypto.sign(payload, otherKeyPair);
      final publicKey = await keyPair.extractPublicKey();
      final isValid = await crypto.verify(payload, signature, publicKey);

      expect(isValid, isFalse);
    });
  });
}
