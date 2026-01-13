import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Verify schema setup for recommendation system', () async {
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
      // 1. Check Tables
      final tablesResult = await connection.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
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
      expect(queues, contains('recommendation_updates'));
      
      print('Verified tables: $tables');
      print('Verified queues: $queues');

    } finally {
      await connection.close();
    }
  });
}
