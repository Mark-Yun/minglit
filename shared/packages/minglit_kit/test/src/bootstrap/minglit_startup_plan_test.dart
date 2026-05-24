import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('MinglitStartupPlan', () {
    test('runs steps in order', () async {
      final calls = <String>[];

      await MinglitStartupPlan(
        steps: [
          MinglitStartupStep.critical('env', () async => calls.add('env')),
          MinglitStartupStep.platform(
            'firebase',
            () async => calls.add('firebase'),
          ),
          MinglitStartupStep.degradable(
            'statsig',
            () async => calls.add('statsig'),
          ),
        ],
      ).run();

      expect(calls, ['env', 'firebase', 'statsig']);
    });

    test('critical step failure is rethrown and stops later steps', () async {
      final calls = <String>[];
      final error = StateError('missing env');

      await expectLater(
        MinglitStartupPlan(
          steps: [
            MinglitStartupStep.critical('env', () async {
              calls.add('env');
              throw error;
            }),
            MinglitStartupStep.degradable(
              'statsig',
              () async => calls.add('statsig'),
            ),
          ],
        ).run(),
        throwsA(same(error)),
      );

      expect(calls, ['env']);
    });

    test('degradable failure is collected and startup continues', () async {
      final calls = <String>[];
      final error = StateError('statsig offline');

      final result = await MinglitStartupPlan(
        steps: [
          MinglitStartupStep.degradable('statsig', () async {
            calls.add('statsig');
            throw error;
          }),
          MinglitStartupStep.critical('supabase', () async {
            calls.add('supabase');
          }),
        ],
      ).run();

      expect(calls, ['statsig', 'supabase']);
      expect(result.isDegraded, isTrue);
      expect(result.degradedFailures, hasLength(1));
      expect(result.degradedFailures.single.stepName, 'statsig');
      expect(result.degradedFailures.single.error, same(error));
    });

    test('platform failure is collected and startup continues', () async {
      final result = await MinglitStartupPlan(
        steps: [
          MinglitStartupStep.platform('display', () async {
            throw UnsupportedError('display mode');
          }),
          MinglitStartupStep.critical('supabase', () async {}),
        ],
      ).run();

      expect(result.isDegraded, isTrue);
      expect(result.degradedFailures.single.stepName, 'display');
    });

    test('critical timeout fails startup', () async {
      await expectLater(
        MinglitStartupPlan(
          steps: [
            MinglitStartupStep.critical(
              'supabase',
              () => Completer<void>().future,
              timeout: const Duration(milliseconds: 1),
            ),
          ],
        ).run(),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('degradable timeout is collected', () async {
      final result = await MinglitStartupPlan(
        steps: [
          MinglitStartupStep.degradable(
            'statsig',
            () => Completer<void>().future,
            timeout: const Duration(milliseconds: 1),
          ),
        ],
      ).run();

      expect(result.isDegraded, isTrue);
      expect(result.degradedFailures.single.error, isA<TimeoutException>());
    });
  });
}
