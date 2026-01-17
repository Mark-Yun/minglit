// Test verification requires print output.
// ignore_for_file: avoid_print

import 'package:test/test.dart';

import 'utils/test_database.dart';

void main() {
  test('Verify Database Extensions', () async {
    final connection = await TestDatabase.createConnection();

    try {
      final result = await connection.execute(
        "SELECT extname FROM pg_extension WHERE extname IN ('vector', 'pgmq')",
      );

      final installedExtensions = result.map((row) => row[0]).toList();
      print('Installed Extensions: $installedExtensions');

      expect(installedExtensions, contains('vector'));
      expect(installedExtensions, contains('pgmq'));
    } finally {
      await connection.close();
    }
  });
}
