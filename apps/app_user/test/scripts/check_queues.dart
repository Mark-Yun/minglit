import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Data Consistency Check ---');
    
    // 1. Get a sample message from queue
    final sampleRes = await connection.execute('SELECT message FROM pgmq.q_q_vectors LIMIT 1');
    final payload = sampleRes.first[0]! as Map<String, dynamic>;
    final partyIdInQueue = payload['payload']['id'];
    print('Party ID in Queue: $partyIdInQueue');

    // 2. Check if this ID exists in public.parties
    final partyRes = await connection.execute("SELECT id, title FROM public.parties WHERE id = '$partyIdInQueue'");
    if (partyRes.isEmpty) {
      print('❌ ERROR: Party ID $partyIdInQueue NOT FOUND in public.parties table!');
    } else {
      print('✅ SUCCESS: Party found: ${partyRes.first[1]}');
    }

    // 3. Count total parties
    final countRes = await connection.execute('SELECT count(*) FROM public.parties');
    print('Total Parties in DB: ${countRes.first[0]}');

  } finally {
    await connection.close();
  }
}
