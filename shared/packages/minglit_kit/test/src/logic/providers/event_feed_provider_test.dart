import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/event_feed_type.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:minglit_kit/src/logic/providers/event_feed_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_utils.dart';

class MockEventRepository extends Mock implements EventRepository {}

class MockEvent extends Mock implements Event {}

void main() {
  setUpAll(() {
    registerFallbackValue(EventFeedType.nearest);
  });

  group('fetchEventFeedProvider', () {
    test('returns list of events when repository returns data', () async {
      final mockRepo = MockEventRepository();
      final mockEvent = MockEvent();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [mockEvent]);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      final result = await container.read(
        fetchEventFeedProvider(type: EventFeedType.newArrivals).future,
      );

      expect(result, hasLength(1));
      expect(result.first, mockEvent);
    });

    test('returns empty list when repository returns empty', () async {
      final mockRepo = MockEventRepository();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      final result = await container.read(
        fetchEventFeedProvider(type: EventFeedType.closingSoon).future,
      );

      expect(result, isEmpty);
    });

    test('provider enters error state when repository throws', () async {
      final mockRepo = MockEventRepository();

      when(
        () => mockRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('Network error'));

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      // Wait for the provider to settle into error state
      await expectLater(
        container.read(fetchEventFeedProvider(type: EventFeedType.nearest).future),
        throwsA(anything),
      );
    });
  });

  group('eventDetailProvider', () {
    test('returns event when repository returns data', () async {
      final mockRepo = MockEventRepository();
      final mockEvent = MockEvent();

      when(
        () => mockRepo.getEventById(any()),
      ).thenAnswer((_) async => mockEvent);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWith((ref) => mockRepo)],
      );

      final result = await container.read(
        eventDetailProvider('test-event-id').future,
      );

      expect(result, mockEvent);
    });
  });
}
