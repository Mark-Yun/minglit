
// ignore_for_file: avoid_print

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Verify Database Extensions', () async {
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
      final result = await connection.execute(
        "SELECT extname FROM pg_extension WHERE extname IN ('vector', 'pgmq')",
      );

      final installedExtensions = result.map((row) => row[0]).toList();
      print('Installed Extensions: $installedExtensions');

      expect(installedExtensions, contains('vector'));
      expect(installedExtensions, contains('pgmq'));
    }
    finally {
      await connection.close();
    }
  });
}
