// ignore_for_file: avoid_print

import 'dart:math';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  String generateUuid() {
    final random = Random();
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

  test('E2E Pipeline Integration: DB -> Queues -> Dispatcher', () async {
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
      // 1. Setup Partner
      final partnerId = generateUuid();
      await connection.execute(
        "INSERT INTO public.partners (id, name) VALUES ('$partnerId', 'E2E Partner') ON CONFLICT DO NOTHING",
      );

      // 2. Create a new Party
      final partyId = generateUuid();
      print('Creating test party: $partyId');

      await connection.execute("""
        INSERT INTO public.parties (id, partner_id, title, description) 
        VALUES ('$partyId', '$partnerId', 'E2E Test Party', '{"ops":[{"insert":"Test Content"}]}'::jsonb)
      """);

      // 3. Wait a moment for trigger execution (immediate but safe)
      await Future.delayed(const Duration(seconds: 1));

      // 4. Check secondary queues
      final qNotif = await connection.execute(
        "SELECT * FROM pgmq.read('q_notifications', 30, 10)",
      );
      final qVect = await connection.execute(
        "SELECT * FROM pgmq.read('q_vectors', 30, 10)",
      );

      print('q_notifications message count: ${qNotif.length}');
      print('q_vectors message count: ${qVect.length}');

      expect(
        qNotif.length,
        greaterThan(0),
        reason: 'Dispatcher should fan-out to q_notifications',
      );
      expect(
        qVect.length,
        greaterThan(0),
        reason: 'Dispatcher should fan-out to q_vectors',
      );

      // 5. Verify payload content
      final firstMsg = qVect.first;
      // Index 0: msg_id, Index 1: read_ct, Index 2: enqueued_at, Index 3: vt,
      // Index 4: message
      final message = firstMsg[4]! as Map<String, dynamic>;
      expect(message['event_type'], equals('party_created'));
      final record = message['record'] as Map<String, dynamic>;
      expect(record['id'], equals(partyId));
    } finally {
      await connection.close();
    }
  });
}