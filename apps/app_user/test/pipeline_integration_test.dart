import 'dart:developer' as dev;

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('E2E Pipeline Integration: DB -> Queues -> Dispatcher', () async {
    final connection = await Connection.open(
      Endpoint(
        host: '127.0.0.1',
        port: 54321,
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      // 1. Setup Partner
      final partnerId = const Uuid().v4();
      await connection.execute(
        'INSERT INTO public.partners (id, name) VALUES '
        "('$partnerId', 'E2E Partner') ON CONFLICT DO NOTHING",
      );

      // 2. Create a new Party
      final partyId = const Uuid().v4();
      dev.log('Creating test party: $partyId');

      await connection.execute('''
        INSERT INTO public.parties (id, partner_id, title, description) 
        VALUES ('$partyId', '$partnerId', 'E2E Test Party', 
        '{"ops":[{"insert":"Test Content"}]}'::jsonb)
      ''');

      // 3. Wait a moment for trigger execution (immediate but safe)
      await Future<void>.delayed(const Duration(seconds: 1));

      // 4. Check secondary queues
      final qNotif = await connection.execute(
        "SELECT * FROM pgmq.read('q_notifications', 30, 10)",
      );
      final qVect = await connection.execute(
        "SELECT * FROM pgmq.read('q_vectors', 30, 10)",
      );

      dev.log('q_notifications message count: ${qNotif.length}');
      dev.log('q_vectors message count: ${qVect.length}');

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
