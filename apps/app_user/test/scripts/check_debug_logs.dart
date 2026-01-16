import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Checking Debug Logs ---');
    final r = await connection.execute('SELECT message, payload, created_at FROM public.debug_logs ORDER BY created_at DESC LIMIT 10');
    for (final row in r) {
      print('${row[2]} | ${row[0]} | ${row[1]}');
    }
    if (r.isEmpty) print('No debug logs found yet.');

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
