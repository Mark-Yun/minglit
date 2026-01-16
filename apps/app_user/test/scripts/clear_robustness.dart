import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Clearing Robustness Data for Re-run ---');
    await connection.execute('TRUNCATE TABLE public.processed_events');
    await connection.execute('TRUNCATE TABLE public.dead_letter_queue');
    await connection.execute('TRUNCATE TABLE public.party_embeddings');
    print('Tables cleared successfully!');

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
