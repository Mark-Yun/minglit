import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/ticket_token.dart';

void main() {
  group('TicketToken', () {
    final now = DateTime(2026, 1, 15, 12);

    test('creates with required fields', () {
      final token = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc123',
        expiresAt: now,
      );

      expect(token.ticketId, 'ticket_1');
      expect(token.eventId, 'event_1');
      expect(token.userId, 'user_1');
      expect(token.signature, 'abc123');
      expect(token.expiresAt, now);
    });

    test('copyWith creates modified copy', () {
      final original = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc123',
        expiresAt: now,
      );

      final modified = original.copyWith(signature: 'new_sig');

      expect(modified.signature, 'new_sig');
      expect(modified.ticketId, 'ticket_1'); // unchanged
      expect(modified.eventId, 'event_1'); // unchanged
    });

    test('equality works with same values', () {
      final token1 = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc',
        expiresAt: now,
      );

      final token2 = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc',
        expiresAt: now,
      );

      expect(token1, equals(token2));
    });

    test('inequality with different values', () {
      final token1 = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc',
        expiresAt: now,
      );

      final token2 = TicketToken(
        ticketId: 'ticket_2',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc',
        expiresAt: now,
      );

      expect(token1, isNot(equals(token2)));
    });

    test('serializes to JSON and back', () {
      final original = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc123',
        expiresAt: now,
      );

      final json = original.toJson();
      final restored = TicketToken.fromJson(json);

      expect(restored, equals(original));
    });

    test('JSON contains expected keys', () {
      final token = TicketToken(
        ticketId: 'ticket_1',
        eventId: 'event_1',
        userId: 'user_1',
        signature: 'abc123',
        expiresAt: now,
      );

      final json = token.toJson();

      expect(json.containsKey('ticketId'), isTrue);
      expect(json.containsKey('eventId'), isTrue);
      expect(json.containsKey('userId'), isTrue);
      expect(json.containsKey('signature'), isTrue);
      expect(json.containsKey('expiresAt'), isTrue);
    });
  });
}
