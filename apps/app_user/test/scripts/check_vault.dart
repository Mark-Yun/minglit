import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('--- Checking Vault Content ---');
    final r = await connection.execute('SELECT name, decrypted_secret FROM vault.decrypted_secrets');
    for (final row in r) {
      print('Key Name: ${row[0]} | Value Start: ${row[1].toString().substring(0, 10)}...');
    }
    if (r.isEmpty) print('Vault is empty!');

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
