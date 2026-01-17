// Test verification requires print output.
// ignore_for_file: avoid_print

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../utils/test_database.dart';

void main() {
  group('Schema Health Check', () {
    late Connection connection;

    setUpAll(() async {
      connection = await TestDatabase.createConnection();
    });

    tearDownAll(() async {
      await connection.close();
    });

    test('Verify Database Extensions', () async {
      final result = await connection.execute(
        "SELECT extname FROM pg_extension WHERE extname IN ('vector', 'pgmq')",
      );

      final installedExtensions = result.map((row) => row[0]).toList();
      print('Installed Extensions: $installedExtensions');

      expect(installedExtensions, contains('vector'));
      expect(installedExtensions, contains('pgmq'));
    });

    test('Verify Core Tables & Queues', () async {
      // 1. Check Tables
      final tablesResult = await connection.execute(
        'SELECT table_name FROM information_schema.tables WHERE '
        "table_schema = 'public'",
      );
      final tables = tablesResult.map((row) => row[0]! as String).toList();

      final requiredTables = [
        'user_embeddings',
        'party_embeddings',
        'user_actions',
        'event_applications',
        'verification_submissions',
      ];

      for (final table in requiredTables) {
        expect(tables, contains(table), reason: '$table should exist');
      }

      // 2. Check Queues
      final queueResult = await connection.execute(
        'SELECT * FROM pgmq.list_queues()',
      );
      final queues = queueResult.map((row) => row[0]! as String).toList();

      expect(queues, contains('q_vectors'));
      expect(queues, contains('q_notifications'));
      expect(queues, contains('q_global_events'));

      print('Verified tables: $tables');
      print('Verified queues: $queues');
    });
  });
}
