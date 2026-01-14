import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('V2 Robustness Verification', () {
    late Connection conn;

    setUp(() async {
      conn = await Connection.open(
        Endpoint(
          host: '127.0.0.1',
          port: 54322,
          database: 'postgres',
          username: 'postgres',
          password: 'postgres',
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
    });

    tearDown(() async {
      await conn.close();
    });

    test('Idempotency Test', () async {
      final traceId = const Uuid().v4();
      dev.log('Testing Idempotency with ID: $traceId');

      // 1. Manually mark as processed
      await conn.execute(
        "INSERT INTO public.processed_events (id) VALUES ('$traceId')",
      );

      // 2. Put message in queue
      final payload = jsonEncode(<String, dynamic>{
        'id': traceId,
        'type': 'party_created',
        'meta': {'occurred_at': 12345, 'source': 'test', 'attempt': 1},
        'payload': {'id': const Uuid().v4(), 'title': 'Already Processed'},
      });

      await conn.execute("SELECT pgmq.send('q_vectors', '$payload'::jsonb)");

      // 3. Invoke Worker
      final resp = await http.post(
        Uri.parse('http://127.0.0.1:54321/functions/v1/vector-worker'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
        },
        body: jsonEncode(<String, dynamic>{'batch_size': 1}),
      );
      dev.log('Worker Response: ${resp.statusCode} ${resp.body}');

      // 4. Verify message is gone from queue
      final result = await conn.execute(
        "SELECT * FROM pgmq.q_q_vectors WHERE message->>'id' = '$traceId'",
      );
      expect(
        result.length,
        0,
        reason: 'Message should be deleted even if skipped',
      );
    });

    test('DLQ Test', () async {
      final traceId = const Uuid().v4();
      dev.log('Testing DLQ with ID: $traceId');

      // 1. Put message in queue
      final payload = jsonEncode(<String, dynamic>{
        'id': traceId,
        'type': 'corrupted_event',
        'payload': <String, dynamic>{},
      });
      await conn.execute("SELECT pgmq.send('q_vectors', '$payload'::jsonb)");

      // 2. Manually make it "old" (read_ct > 5)
      await conn.execute(
        'UPDATE pgmq.q_q_vectors SET read_ct = 6 '
        "WHERE message->>'id' = '$traceId'",
      );

      // 3. Invoke Worker
      final resp = await http.post(
        Uri.parse('http://127.0.0.1:54321/functions/v1/vector-worker'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
        },
        body: jsonEncode(<String, dynamic>{'batch_size': 1}),
      );
      dev.log('Worker Response: ${resp.statusCode} ${resp.body}');

      // 4. Verify moved to DLQ
      final dlqResult = await conn.execute(
        'SELECT * FROM public.dead_letter_queue '
        "WHERE payload->>'id' = '$traceId'",
      );
      expect(dlqResult.length, 1, reason: 'Message should be in DLQ');

      final qResult = await conn.execute(
        "SELECT * FROM pgmq.q_q_vectors WHERE message->>'id' = '$traceId'",
      );
      expect(
        qResult.length,
        0,
        reason: 'Message should be gone from original queue',
      );
    });
  });
}