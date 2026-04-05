import 'package:minglit_kit/minglit_kit.dart';

import 'test_mocks.dart';

/// Pre-built collections of fake data for integration tests.

final testPartner = createTestPartner();
final testUser = createTestUser();
final testEvent = createTestEvent();

/// A list of pending applications for the test event.
Map<Event, List<EventApplication>> fakePendingApplications() {
  return {
    testEvent: [
      createTestApplication(
        id: 'app-1',
        userName: '홍길동',
        gender: 'male',
        birthYear: 1998,
      ),
      createTestApplication(
        id: 'app-2',
        userName: '김영희',
        gender: 'female',
        birthYear: 2000,
      ),
    ],
  };
}

/// A list of approved applications for the test event.
Map<Event, List<EventApplication>> fakeApprovedApplications() {
  return {
    testEvent: [
      createTestApplication(
        id: 'app-3',
        status: 'approved',
        userName: '이철수',
        gender: 'male',
        birthYear: 1995,
      ),
    ],
  };
}

/// A list of rejected applications for the test event.
Map<Event, List<EventApplication>> fakeRejectedApplications() {
  return {
    testEvent: [
      createTestApplication(
        id: 'app-4',
        status: 'rejected',
        userName: '박지수',
        gender: 'female',
        birthYear: 2001,
      ),
    ],
  };
}

/// A set of events happening today for checkin tests.
List<Event> fakeTodayEvents({int count = 2}) {
  final now = DateTime.now();
  return List.generate(
    count,
    (i) => Event(
      id: 'today-event-$i',
      partyId: 'test-party-1',
      title: '오늘의 이벤트 ${i + 1}',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 4)),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      currentParticipants: i * 5,
    ),
  );
}
