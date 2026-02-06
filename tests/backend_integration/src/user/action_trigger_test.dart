// ignore_for_file: lines_longer_than_80_chars, avoid_dynamic_calls

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../utils/test_database.dart';

void main() {
  group('User Action Trigger Test', () {
    late Connection connection;
    late String userId;
    late String partyId;

    setUpAll(() async {
      connection = await TestDatabase.createConnection();

      // Find Seeded Data
      final targetBirthYear = DateTime.now().year - 25 + 1;
      final userRes = await connection.execute(
        "SELECT id FROM public.user_profiles WHERE gender = 'male' AND birth_date = '$targetBirthYear-01-01' AND username LIKE '%_ok' LIMIT 1",
      );
      if (userRes.isEmpty) throw Exception('Seeded user (25/Male/Verified) not found');
      userId = userRes.first[0]! as String;

      final partyRes = await connection.execute(
        'SELECT id FROM public.parties LIMIT 1',
      );
      if (partyRes.isEmpty) throw Exception('Seeded party not found');
      partyId = partyRes.first[0]! as String;
    });

    tearDownAll(() async {
      await connection.close();
    });

    test('Trigger on user_actions should dispatch event to q_vectors',
        () async {
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
      await Future<void>.delayed(const Duration(milliseconds: 1000));

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

          // Cleanup message from queue
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
