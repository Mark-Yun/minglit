// ignore_for_file: avoid_print

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Verify PGMQ Message Enqueue', () async {
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
      // 1. Send Message
      await connection.execute(
        "SELECT pgmq.send('test_queue', '{\"foo\": \"bar\"}')",
      );

      // 2. Read Message
      final result = await connection.execute(
        "SELECT * FROM pgmq.read('test_queue', 30, 1)",
      );

      print('PGMQ Read Result: $result');
      expect(result.isNotEmpty, true);
    } finally {
      await connection.close();
    }
  });
}
