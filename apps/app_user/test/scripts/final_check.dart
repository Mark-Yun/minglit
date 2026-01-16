import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Final Data Inspection ---');
    
    final r = await connection.execute('SELECT party_id, updated_at FROM public.party_embeddings');
    print('Embedding Count: ${r.length}');
    for (final row in r) {
      print('ID: ${row[0]} | At: ${row[1]}');
    }

    final p = await connection.execute('SELECT id, title FROM public.parties LIMIT 5');
    print('\nSample Parties in DB:');
    for (final row in p) {
      print('ID: ${row[0]} | Title: ${row[1]}');
    }

  } finally {
    await connection.close();
  }
}
