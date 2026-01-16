// ignore_for_file: lines_longer_than_80_chars, avoid_dynamic_calls, avoid_catches_without_on_clauses

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
      // 1. Send directly via pgmq.send (since wrapper is only for read/delete)
      await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"bar\"}'::jsonb)",
      );

      // 2. Read using wrapper: public.pgmq_read
      final result = await connection.execute(
        "SELECT * FROM public.pgmq_read('$testQueue', 30, 1)",
      );

      expect(result, isNotEmpty);
      final msg = result.first[0] as Map<String, dynamic>;
      expect(msg['message']['foo'], equals('bar'));
    });

    test('should delete message using wrapper', () async {
      // 1. Send
      final sendRes = await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"delete_me\"}'::jsonb)",
      );
      final msgId = sendRes.first[0] as int;

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
    // We rely on 'q_vectors' queue which is created by migration.
    // We will insert into 'user_actions' which has a trigger.

    test('Trigger on user_actions should dispatch event to q_vectors', () async {
      final userId = uuid.v4();
      final partyId = uuid.v4();
      final partnerId = uuid.v4();

      // Setup Prerequisites: User, Partner, Party
      // Note: We use raw insert into auth.users to bypass foreign key constraints logic that might be complex
      // But auth.users is protected. We will insert into user_profiles directly if we can,
      // BUT user_profiles has FK to auth.users.
      // So we must insert into auth.users first.

      try {
        await connection.execute(
          "INSERT INTO auth.users (id, email) VALUES ('$userId', 'test_sql_$userId@example.com')",
        );
      } catch (e) {
        // Ignore if user exists or permission issue (if testing as postgres user, should be fine)
      }

      await connection.execute(
        "INSERT INTO public.partners (id, name) VALUES ('$partnerId', 'Test SQL Partner') ON CONFLICT (id) DO NOTHING",
      );

      await connection.execute(
        "INSERT INTO public.parties (id, partner_id, title) VALUES ('$partyId', '$partnerId', 'Test SQL Party') ON CONFLICT (id) DO NOTHING",
      );

      // 1. Insert Action (Trigger fires here)
      await connection.execute(
        "INSERT INTO public.user_actions (user_id, party_id, action_type) VALUES ('$userId', '$partyId', 'view')",
      );

      // 2. Check Queue
      // Wait a bit for trigger -> function -> queue
      await Future.delayed(const Duration(milliseconds: 500));

      final qResult = await connection.execute(
        "SELECT * FROM public.pgmq_read('q_vectors', 10, 10)",
      );

      // Find our message
      var found = false;
      for (final row in qResult) {
        final msg = row[0] as Map<String, dynamic>;
        final payload = msg['message'] as Map<String, dynamic>;

        if (payload['type'] == 'user_interaction' &&
            payload['payload']['user_id'] == userId &&
            payload['payload']['party_id'] == partyId) {
          found = true;
          // Cleanup message
          final msgId = msg['msg_id'] as int;
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
