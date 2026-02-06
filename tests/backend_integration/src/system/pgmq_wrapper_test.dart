// ignore_for_file: avoid_dynamic_calls -- PGMQ library returns dynamic types that require dynamic calls for testing

import 'package:minglit_kit/minglit_core.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../utils/test_database.dart';

void main() {
  group('PGMQ Wrappers Test', () {
    late Connection connection;
    const testQueue = 'test_queue_wrappers';

    setUpAll(() async {
      connection = await TestDatabase.createConnection();
    });

    tearDownAll(() async {
      await connection.close();
    });

    setUp(() async {
      await connection.execute("SELECT pgmq.create('$testQueue')");
    });

    tearDown(() async {
      try {
        await connection.execute("SELECT pgmq.drop_queue('$testQueue')");
      } on Object catch (e, st) {
        Log.e('Failed to drop PGMQ queue: $testQueue', e, st);
      }
    });

    test('should send and read message using wrappers', () async {
      await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"bar\"}'::jsonb)",
      );

      final result = await connection.execute(
        "SELECT * FROM public.pgmq_read('$testQueue', 30, 1)",
      );

      expect(result, isNotEmpty);
      final dynamic firstRow = result.first[0];
      final msg = firstRow as Map<String, dynamic>;
      expect(msg['message']['foo'], equals('bar'));
    });

    test('should delete message using wrapper', () async {
      final sendRes = await connection.execute(
        "SELECT pgmq.send('$testQueue', '{\"foo\": \"delete_me\"}'::jsonb)",
      );
      final dynamic firstRow = sendRes.first[0];
      final msgId = firstRow as int;

      final delRes = await connection.execute(
        "SELECT public.pgmq_delete('$testQueue', $msgId)",
      );

      expect(delRes.first[0], isTrue);

      final readRes = await connection.execute(
        "SELECT * FROM public.pgmq_read('$testQueue', 30, 1)",
      );
      expect(readRes, isEmpty);
    });
  });
}
