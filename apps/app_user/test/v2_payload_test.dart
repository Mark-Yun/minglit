import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  String generateUuid() {
    final random = math.Random();
    final parts = List.generate(5, (i) {
      if (i == 0) {
        return random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
      }
      if (i == 1 || i == 2 || i == 3) {
        return random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
      }
      return (random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')) +
          (random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0'));
    });
    return parts.join('-');
  }

  test('Verify V2 Standard Payload Structure', () async {
    final connection = await Connection.open(
      Endpoint(
        host: '127.0.0.1',
        port: 54322,
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      // 1. Setup Data
      final userId = generateUuid();
      final partyId = generateUuid();
      final partnerId = generateUuid();

      await connection.execute(
        'INSERT INTO auth.users (id, email) VALUES '
        "('$userId', 'v2test@example.com') ON CONFLICT DO NOTHING",
      );
      await connection.execute(
        'INSERT INTO public.partners (id, name) VALUES '
        "('$partnerId', 'V2 Partner') ON CONFLICT DO NOTHING",
      );
      await connection.execute(
        'INSERT INTO public.parties (id, partner_id, title) VALUES '
        "('$partyId', '$partnerId', 'V2 Test Party') ON CONFLICT DO NOTHING",
      );

      // 2. Trigger Event
      dev.log('Inserting User Action...');
      await connection.execute(
        'INSERT INTO public.user_actions (user_id, party_id, action_type) '
        "VALUES ('$userId', '$partyId', 'view')",
      );

      // 3. Wait & Read Queue
      await Future<void>.delayed(const Duration(seconds: 1));
      final result = await connection.execute(
        "SELECT * FROM pgmq.read('q_vectors', 30, 1)",
      );

      expect(result.length, greaterThan(0));
      final message = result.first[4]! as Map<String, dynamic>;

      dev.log('V2 Payload: $message');

      // 4. Verify Structure
      expect(message.containsKey('id'), isTrue, reason: 'Missing trace ID');
      expect(message.containsKey('meta'), isTrue, reason: 'Missing meta');
      final meta = message['meta'] as Map<String, dynamic>;
      expect(meta['occurred_at'], isA<int>());
      expect(meta['attempt'], equals(1));
      expect(message.containsKey('actor'), isTrue, reason: 'Missing actor');
      expect(message.containsKey('payload'), isTrue, reason: 'Missing payload');
    } finally {
      await connection.close();
    }
  });
}
