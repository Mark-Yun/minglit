import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MockEventRepository extends EventRepository {
  @override
  Future<Event> getEventById(String eventId) async {
    if (eventId == 'test_id') {
      return Event(
        id: 'test_id',
        title: 'Test Event',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        partyId: 'party_id',
        entryGroups: const [],
        tickets: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    throw Exception('Event not found');
  }
}

void main() {
  test('EventDetailController loads event data', () async {
    final container = ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(MockEventRepository()),
      ],
    );
    addTearDown(container.dispose);

    final event = await container.read(
      eventDetailControllerProvider('test_id').future,
    );

    expect(event.title, 'Test Event');
  });
}
