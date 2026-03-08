import 'package:app_partner/src/features/party/event/detail/event_application_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
// Explicit import

/// Local helper
ProviderContainer createContainer({
  ProviderContainer? parent,
  List<dynamic> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides.cast(),
    observers: observers,
  );
  addTearDown(container.dispose);
  return container;
}

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late MockEventRepository mockRepo;

  setUp(() {
    mockRepo = MockEventRepository();
  });

  group('EventApplicationController Tests', () {
    test(
      'Should throw TypeError if repository returns malformed list',
      () async {
        final exception = TypeError(); // Simulating the exact TypeError

        when(
          () => mockRepo.getApplicationsByEventId('event_1'),
        ).thenThrow(exception);

        final container = createContainer(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Verify that reading the provider rethrows the error
        expect(
          () => container.read(eventApplicationsProvider('event_1').future),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('Should return parsed list when data is correct', () async {
      final validData = [
        EventApplication(
          id: 'app_1',
          eventId: 'event_1',
          userId: 'user_1',
          ticketId: 'ticket_1',
          status: 'approved',
          paymentId: 'pay_1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(
        () => mockRepo.getApplicationsByEventId('event_1'),
      ).thenAnswer((_) async => validData);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final result = await container.read(
        eventApplicationsProvider('event_1').future,
      );
      expect(result, isA<List<EventApplication>>());
      expect(result.length, 1);
      expect(result.first.id, 'app_1');
    });
  });
}
