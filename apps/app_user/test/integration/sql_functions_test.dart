// ignore_for_file: lines_longer_than_80_chars, avoid_dynamic_calls, avoid_catches_without_on_clauses, document_ignores

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late Connection connection;
  const uuid = Uuid();

  setUpAll(() async {
    connection = await Connection.open(
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

  tearDownAll(() async {
    await connection.close();
  });

  group('PGMQ Wrappers Test', () {
    const testQueue = 'test_queue_wrappers';

    setUp(() async {
      await connection.execute("SELECT pgmq.create('$testQueue')");
    });

    tearDown(() async {
      await connection.execute("SELECT pgmq.drop_queue('$testQueue')");
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
      // 1. Send
      final sendRes = await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"delete_me\"}'::jsonb)",
      );
      final dynamic firstRow = sendRes.first[0];
      final msgId = firstRow as int;

      // 2. Delete using wrapper: public.pgmq_delete
      final delRes = await connection.execute(
        "SELECT public.pgmq_delete('$testQueue', $msgId)",
      );

      expect(delRes.first[0], isTrue);

      // 3. Verify empty
      final readRes = await connection.execute(
        "SELECT * FROM public.pgmq_read('$testQueue', 30, 1)",
      );
      expect(readRes, isEmpty);
    });
  });

  group('Pipeline Dispatcher Test', () {
    test('Trigger on user_actions should dispatch event to q_vectors', () async {
      final userId = uuid.v4();
      final partyId = uuid.v4();
      final partnerId = uuid.v4();

      // Setup Prerequisites
      try {
        await connection.execute(
          "INSERT INTO auth.users (id, email) VALUES ('$userId', 'test_sql_$userId@example.com')",
        );
      } catch (e) {
        // Ignore
      }

      await connection.execute(
        "INSERT INTO public.partners (id, name) VALUES ('$partnerId', 'Test SQL Partner') ON CONFLICT (id) DO NOTHING",
      );

      await connection.execute(
        "INSERT INTO public.parties (id, partner_id, title) VALUES ('$partyId', '$partnerId', 'Test SQL Party') ON CONFLICT (id) DO NOTHING",
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
