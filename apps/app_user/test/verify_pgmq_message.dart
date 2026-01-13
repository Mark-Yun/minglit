import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Verify PGMQ has message', () async {
    final connection = await Connection.open(
      Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      final result = await connection.execute("SELECT * FROM pgmq.read('recommendation_updates', 10, 1)");
      print('PGMQ Messages: ${result.length}');
      expect(result.length, greaterThan(0));
    } finally {
      await connection.close();
    }
  });
}
