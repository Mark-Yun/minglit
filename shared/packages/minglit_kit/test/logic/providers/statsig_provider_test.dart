import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/logic/providers/statsig_provider.dart';

void main() {
  group('MingLitEvent', () {
    test('has exactly 7 event constants', () {
      expect(MingLitEvent.appOpened, 'app_opened');
      expect(MingLitEvent.eventViewed, 'event_viewed');
      expect(MingLitEvent.eventApplied, 'event_applied');
      expect(MingLitEvent.paymentCompleted, 'payment_completed');
      expect(MingLitEvent.paymentFailed, 'payment_failed');
      expect(MingLitEvent.matchingResult, 'matching_result');
      expect(MingLitEvent.errorOccurred, 'error_occurred');
    });
  });

  group('StatsigAnalytics', () {
    test('initialize does not throw when key is empty', () async {
      await expectLater(
        StatsigAnalytics.initialize('', tier: 'development'),
        completes,
      );
    });

    test(
      'initialize does not throw when key is FILL_THIS placeholder',
      () async {
        await expectLater(
          StatsigAnalytics.initialize('FILL_THIS', tier: 'development'),
          completes,
        );
      },
    );

    test('logEvent does not throw when not initialized', () {
      expect(
        () => StatsigAnalytics.logEvent(MingLitEvent.appOpened),
        returnsNormally,
      );
    });

    test('checkGate returns false when not initialized', () async {
      final result = StatsigAnalytics.checkGate('test_gate');
      expect(result, isFalse);
    });

    test('updateUser does not throw when not initialized', () async {
      await expectLater(StatsigAnalytics.updateUser('user-123'), completes);
    });

    test('shutdown does not throw when not initialized', () async {
      await expectLater(StatsigAnalytics.shutdown(), completes);
    });
  });
}
