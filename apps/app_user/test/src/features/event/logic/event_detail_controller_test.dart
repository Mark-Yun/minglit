import 'dart:async';

import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;

  // Test Data
  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    title: 'Test Event',
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
  });

  group('EventDetailController', () {
    test('returns event when repository succeeds', () async {
      when(
        () => mockEventRepo.getEventById('event_1'),
      ).thenAnswer((_) async => testEvent);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        eventDetailControllerProvider('event_1').future,
      );
      expect(result, testEvent);
    });

    // Fix #1009: In Riverpod 3, a provider that errors during build() enters
    // an AsyncLoading(error, retrying) loop instead of settling into
    // AsyncError. Verify the error via AsyncValue.hasError / .error.
    test('throws exception when repository fails', () async {
      final exception = Exception('Network Error');
      when(
        () => mockEventRepo.getEventById('event_1'),
      ).thenAnswer((_) async => throw exception);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      // Wait for the provider to report the error (it will be in
      // AsyncLoading+error+retrying state in Riverpod 3).
      final completer = Completer<void>();
      final subscription = container.listen(
        eventDetailControllerProvider('event_1'),
        (prev, next) {
          if (next.hasError && !completer.isCompleted) {
            completer.complete();
          }
        },
      );
      addTearDown(subscription.close);

      await completer.future;

      final state = container.read(
        eventDetailControllerProvider('event_1'),
      );
      expect(state.hasError, isTrue);
      expect(state.error, exception);
    });
  });
}
