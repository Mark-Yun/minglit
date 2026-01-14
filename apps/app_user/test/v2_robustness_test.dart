import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'package:http/http.dart' as http;
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
      final traceId = generateUuid();
      log('Testing Idempotency with ID: $traceId');

      // 1. Manually mark as processed
      await conn.execute(
        "INSERT INTO public.processed_events (id) VALUES ('$traceId')",
      );

      // 2. Put message in queue
      final payload = jsonEncode({
        'id': traceId,
        'type': 'party_created',
        'meta': {'occurred_at': 12345, 'source': 'test', 'attempt': 1},
        'payload': {'id': generateUuid(), 'title': 'Already Processed'},
      });
      await conn.execute("SELECT pgmq.send('q_vectors', '$payload'::jsonb)");

      // 3. Invoke Worker
      final resp = await http.post(
        Uri.parse('http://127.0.0.1:54321/functions/v1/vector-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
        },
        body: jsonEncode({'batch_size': 1}),
      );
      log('Worker Response: ${resp.statusCode} ${resp.body}');

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
      final traceId = generateUuid();
      log('Testing DLQ with ID: $traceId');

      // 1. Put message in queue
      final payload = jsonEncode({
        'id': traceId,
        'type': 'corrupted_event',
        'payload': {},
      });
      await conn.execute("SELECT pgmq.send('q_vectors', '$payload'::jsonb)");

      // 2. Manually make it "old" (read_ct > 5)
      await conn.execute(
        "UPDATE pgmq.q_q_vectors SET read_ct = 6 "
        "WHERE message->>'id' = '$traceId'",
      );

      // 3. Invoke Worker
      final resp = await http.post(
        Uri.parse('http://127.0.0.1:54321/functions/v1/vector-worker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sb_secret_N7UND0UgjKTVK-Uodkm0Hg_xSvEMPvz',
        },
        body: jsonEncode({'batch_size': 1}),
      );
      log('Worker Response: ${resp.statusCode} ${resp.body}');

      // 4. Verify moved to DLQ
      final dlqResult = await conn.execute(
        "SELECT * FROM public.dead_letter_queue "
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
