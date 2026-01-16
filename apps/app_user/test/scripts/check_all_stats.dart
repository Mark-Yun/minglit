import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    final pe = await connection.execute('SELECT count(*) FROM public.processed_events');
    final dlq = await connection.execute('SELECT count(*) FROM public.dead_letter_queue');
    final emb = await connection.execute('SELECT count(*) FROM public.party_embeddings');
    final q = await connection.execute('SELECT count(*) FROM pgmq.q_q_vectors');

    print('--- Pipeline v2 Stats ---');
    print('Processed Events Table: ${pe.first[0]}');
    print('Dead Letter Queue Table: ${dlq.first[0]}');
    print('Party Embeddings Table: ${emb.first[0]}');
    print('Remaining in Queue: ${q.first[0]}');

  } finally {
    await connection.close();
  }
}
