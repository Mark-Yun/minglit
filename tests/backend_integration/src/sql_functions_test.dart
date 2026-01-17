// ignore_for_file: lines_longer_than_80_chars, avoid_dynamic_calls, avoid_catches_without_on_clauses, document_ignores

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'utils/test_database.dart';

void main() {
  late Connection connection;

  setUpAll(() async {
    connection = await TestDatabase.createConnection();
  });

  tearDownAll(() async {
    await connection.close();
  });

  group('PGMQ Wrappers Test', () {
    const testQueue = 'test_queue_wrappers';

    setUp(() async {
      await connection.execute("SELECT pgmq.create('$testQueue')");
    });

    tearDown(() async {
      try {
        await connection.execute("SELECT pgmq.drop_queue('$testQueue')");
      } catch (_) {}
    });

    test('should send and read message using wrappers', () async {
      // 1. Send directly via pgmq.send
      await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"bar\"}'::jsonb)",
      );

      // 2. Read using wrapper: public.pgmq_read
      final result = await connection.execute(
        "SELECT * FROM public.pgmq_read('$testQueue', 30, 1)",
      );

      expect(result, isNotEmpty);
      final dynamic firstRow = result.first[0];
      final msg = firstRow as Map<String, dynamic>;
      expect(msg['message']['foo'], equals('bar'));
    });

    test('should delete message using wrapper', () async {
      final sendRes = await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"delete_me\"}'::jsonb)",
      );
      final dynamic firstRow = sendRes.first[0];
      final msgId = firstRow as int;

      final delRes = await connection.execute(
        "SELECT public.pgmq_delete('$testQueue', $msgId)",
      );

      expect(delRes.first[0], isTrue);

      final readRes = await connection.execute(
        "SELECT * FROM public.pgmq_read('$testQueue', 30, 1)",
      );
      expect(readRes, isEmpty);
    });
  });

  group('Pipeline Dispatcher Test', () {
    late String userId;
    late String partyId;

    setUpAll(() async {
      // 1. Find Seeded User (user_1)
      final userRes = await connection.execute(
        "SELECT id FROM public.user_profiles WHERE username = 'user_1' LIMIT 1",
      );
      if (userRes.isEmpty) throw Exception('Seeded user_1 not found');
      userId = userRes.first[0] as String;

      // 2. Find Seeded Party
      final partyRes = await connection.execute(
        "SELECT id FROM public.parties LIMIT 1",
      );
      if (partyRes.isEmpty) throw Exception('Seeded party not found');
      partyId = partyRes.first[0] as String;
    });

    test('Trigger on user_actions should dispatch event to q_vectors', () async {
      print('🧪 Testing Trigger with User: $userId, Party: $partyId');

      // 0. Enable Routing
      await connection.execute(
        "UPDATE public.event_routes SET is_active = true WHERE event_type = 'user_interaction'",
      );

      // 1. Insert Action
      await connection.execute(
        "INSERT INTO public.user_actions (user_id, party_id, action_type) VALUES ('$userId', '$partyId', 'view')",
      );

      // 2. Check Queue
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final qResult = await connection.execute(
        "SELECT * FROM public.pgmq_read('q_vectors', 10, 10)",
      );

      var found = false;
      for (final row in qResult) {
        final dynamic firstCol = row[0];
        final msg = firstCol as Map<String, dynamic>;
        final payload = msg['message'] as Map<String, dynamic>;

        if (payload['type'] == 'user_interaction' &&
            payload['payload']['user_id'] == userId &&
            payload['payload']['party_id'] == partyId) {
          found = true;
          final dynamic mId = msg['msg_id'];
          final msgId = mId as int;
          await connection.execute(
            "SELECT public.pgmq_delete('q_vectors', $msgId)",
          );
          break;
        }
      }

      expect(found, isTrue, reason: 'Event should be found in q_vectors queue');
    });
  });
}