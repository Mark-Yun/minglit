// Test verification requires print output.
// ignore_for_file: avoid_print

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'utils/test_database.dart';

void main() {
  test('Verify schema setup for recommendation system', () async {
    final connection = await TestDatabase.createConnection();

    try {
      // 1. Check Tables
      final tablesResult = await connection.execute(
        'SELECT table_name FROM information_schema.tables WHERE '
        "table_schema = 'public'",
      );
      final tables = tablesResult.map((row) => row[0]! as String).toList();
      expect(tables, contains('user_embeddings'));
      expect(tables, contains('party_embeddings'));
      expect(tables, contains('user_actions'));

      // 2. Check Queue
      final queueResult = await connection.execute(
        'SELECT * FROM pgmq.list_queues()',
      );
      final queues = queueResult.map((row) => row[0]! as String).toList();
      
      // 'recommendation_updates' might be old name, checking 'q_vectors' instead
      expect(queues, contains('q_vectors'));

      print('Verified tables: $tables');
      print('Verified queues: $queues');
    } finally {
      await connection.close();
    }
  });
}
