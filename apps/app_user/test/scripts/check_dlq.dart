import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Checking DLQ ---');
    final dlqRes = await connection.execute('SELECT count(*) FROM public.dead_letter_queue');
    print('DLQ Count: ${dlqRes.first[0]}');
    
    if (dlqRes.first[0]! as int > 0) {
      final reason = await connection.execute('SELECT error_reason FROM public.dead_letter_queue LIMIT 1');
      print('First Error Reason: ${reason.first[0]}');
    }

  } finally {
    await connection.close();
  }
}
