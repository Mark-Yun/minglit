import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Checking Embeddings ---');
    
    // 1. Party Embeddings
    final pRes = await connection.execute('SELECT count(*) FROM public.party_embeddings');
    print('Party Embeddings: ${pRes.first[0]}');

    // 2. Queue Status
    final qRes = await connection.execute('SELECT count(*) FROM pgmq.q_q_vectors');
    print('Remaining Queue (Vectors): ${qRes.first[0]}');

  } finally {
    await connection.close();
  }
}
