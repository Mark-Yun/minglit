import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    // Get a valid partner ID first
    final partnerRes = await connection.execute('SELECT id FROM public.partners LIMIT 1');
    if (partnerRes.isEmpty) {
      print('No partners found. Seed first.');
      return;
    }
    final partnerId = partnerRes.first[0];

    print('Creating Real Final Test Party...');
    await connection.execute("""
      INSERT INTO public.parties (partner_id, title, description) 
      VALUES ('$partnerId', 'Real Final Test Party', '{"ops":[{"insert":"This should be vectorized now!"}]}'::jsonb)
    """);
    print('New party created successfully!');

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
