
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Verify pgvector and pgmq extensions are installed', () async {
    final connection = await Connection.open(
      Endpoint(
        host: '127.0.0.1',
        port: 54322,
        database: 'postgres',
        username: 'postgres',
        password: 'postgres', // Supabase local default
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      final result = await connection.execute(
        "SELECT extname FROM pg_extension",
      );

      final installedExtensions = result.map((row) => row[0] as String).toList();
      print('DEBUG: All installed extensions: $installedExtensions');

      expect(installedExtensions, contains('vector'));
      expect(installedExtensions, contains('pgmq'));
    } finally {
      await connection.close();
    }
  });
}
