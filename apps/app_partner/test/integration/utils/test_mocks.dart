import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Creates a test [Partner] with sensible defaults.
Partner createTestPartner({
  String id = 'test-partner-1',
  String name = '테스트 파트너',
}) {
  return Partner(id: id, name: name);
}

/// Creates a test [User] (Supabase) with sensible defaults.
User createTestUser({
  String id = 'test-user-1',
  String email = 'test@minglit.com',
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: {'email': email},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
  );
}

/// Creates an [EventApplication] for use in tests.
EventApplication createTestApplication({
  required String id,
  String eventId = 'test-event-1',
  String ticketId = 'test-ticket-1',
  String status = 'pending',
  String? userName,
  String? gender,
  int? birthYear,
}) {
  final now = DateTime(2026, 4, 1, 14);
  return EventApplication(
    id: id,
    eventId: eventId,
    ticketId: ticketId,
    userId: 'user-$id',
    status: status,
    createdAt: now.subtract(const Duration(hours: 1)),
    updatedAt: now,
    user: userName != null
        ? UserProfile(
            id: 'user-$id',
            name: userName,
            username: userName.toLowerCase().replaceAll(' ', '_'),
            gender: gender,
            birthYear: birthYear,
          )
        : null,
  );
}

/// Creates a test [Event] suitable for application management tests.
Event createTestEvent({
  String id = 'test-event-1',
  String partyId = 'test-party-1',
  String title = '테스트 이벤트',
}) {
  final now = DateTime(2026, 4, 5, 18);
  return Event(
    id: id,
    partyId: partyId,
    title: title,
    startTime: now,
    endTime: now.add(const Duration(hours: 3)),
    createdAt: now.subtract(const Duration(days: 7)),
    updatedAt: now.subtract(const Duration(days: 7)),
    currentParticipants: 0,
  );
}
