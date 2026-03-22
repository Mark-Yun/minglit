import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../utils/mocks.dart';

// Re-export existing mocks from unit test utils
export '../../utils/mocks.dart';

// --- Additional Repository Mocks for integration tests ---
class MockSocialRepository extends Mock implements SocialRepository {}

class MockPartnerRepository extends Mock implements PartnerRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockMatchingRepository extends Mock implements MatchingRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

/// Creates a MockUser with realistic test metadata.
User createMockUserForTest({
  String id = 'test-user-id',
  String email = 'test@example.com',
  String name = 'Test User',
  String? avatarUrl,
}) {
  final user = MockUser();
  when(() => user.id).thenReturn(id);
  when(() => user.email).thenReturn(email);
  when(() => user.userMetadata).thenReturn({
    'full_name': name,
    'avatar_url': avatarUrl,
  });
  return user;
}

/// Creates a list of test Event objects for rendering tests.
List<Event> createMockEventsForTest({int count = 2}) {
  return List.generate(
    count,
    (i) => Event(
      id: 'test-event-$i',
      partyId: 'test-party-$i',
      title: 'Test Event $i',
      startTime: DateTime.now().add(Duration(days: i + 1)),
      endTime: DateTime.now().add(Duration(days: i + 1, hours: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tickets: [
        Ticket(
          id: 'test-ticket-$i',
          name: 'General',
          price: 15000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
    ),
  );
}
