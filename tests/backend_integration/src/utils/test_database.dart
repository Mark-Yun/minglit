import 'package:postgres/postgres.dart';

/// Centralized Database Connection Helper for Tests
class TestDatabase {
  static const _host = '127.0.0.1';
  static const _port = 54322;
  static const _database = 'postgres';
  static const _username = 'postgres';
  static const _password = 'postgres';

  /// Creates a new connection to the local Postgres instance.
  static Future<Connection> createConnection() async {
    return Connection.open(
      Endpoint(
        host: _host,
        port: _port,
        database: _database,
        username: _username,
        password: _password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }
}
