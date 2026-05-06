import 'package:app_user/src/features/tickets/active_event_banners_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime(2026, 5, 6, 19);

  // A future time so endTime.isAfter(now) == true (event is not yet ended)
  final futureEnd = now.add(const Duration(hours: 3));
  // A past time so endTime.isAfter(now) == false (event has ended time-wise)
  final pastEnd = now.subtract(const Duration(hours: 1));

  Event makeEvent({
    String status = 'scheduled',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Event(
      id: 'event_1',
      partyId: 'party_1',
      title: '테스트 이벤트',
      startTime: startTime ?? now.add(const Duration(hours: 1)),
      endTime: endTime ?? futureEnd,
      createdAt: now,
      updatedAt: now,
      status: status,
    );
  }

  EventApplication makeApplication({
    required Event event,
    DateTime? matchResultsViewedAt,
  }) {
    return EventApplication(
      id: 'app_1',
      eventId: event.id,
      ticketId: 'ticket_1',
      userId: 'user_1',
      status: 'approved',
      createdAt: now,
      updatedAt: now,
      event: event,
      matchResultsViewedAt: matchResultsViewedAt,
    );
  }

  EventLifecyclePhase resolve({
    required EventApplication application,
    bool isCheckedIn = false,
    bool isNoShow = false,
    bool hasMatchResults = false,
    bool hasMatchingCandidates = false,
    bool hasSubmittedVotes = false,
  }) {
    return resolveEventLifecyclePhase(
      application: application,
      now: now,
      isCheckedIn: isCheckedIn,
      isNoShow: isNoShow,
      hasMatchResults: hasMatchResults,
      hasMatchingCandidates: hasMatchingCandidates,
      hasSubmittedVotes: hasSubmittedVotes,
    );
  }

  test('noShow=true returns noShow', () {
    final application = makeApplication(event: makeEvent());
    expect(
      resolve(application: application, isNoShow: true),
      EventLifecyclePhase.noShow,
    );
  });

  test(
    'completed event with isCheckedIn=true and matchResultsViewedAt=null returns resultsUnviewed',
    () {
      final event = makeEvent(status: 'completed', endTime: pastEnd);
      final application = makeApplication(
        event: event,
        matchResultsViewedAt: null,
      );
      expect(
        resolve(application: application, isCheckedIn: true),
        EventLifecyclePhase.resultsUnviewed,
      );
    },
  );

  test(
    'completed event with isCheckedIn=true and matchResultsViewedAt non-null returns resultsViewed',
    () {
      final event = makeEvent(status: 'completed', endTime: pastEnd);
      final application = makeApplication(
        event: event,
        matchResultsViewedAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(
        resolve(application: application, isCheckedIn: true),
        EventLifecyclePhase.resultsViewed,
      );
    },
  );

  test(
    'completed event with isCheckedIn=false and hasMatchResults=false returns ended',
    () {
      final event = makeEvent(status: 'completed', endTime: pastEnd);
      final application = makeApplication(event: event);
      expect(
        resolve(application: application),
        EventLifecyclePhase.ended,
      );
    },
  );

  test(
    'ongoing event with hasMatchResults=true and matchResultsViewedAt=null returns resultsUnviewed',
    () {
      final event = makeEvent(status: 'ongoing', endTime: futureEnd);
      final application = makeApplication(
        event: event,
        matchResultsViewedAt: null,
      );
      expect(
        resolve(application: application, hasMatchResults: true),
        EventLifecyclePhase.resultsUnviewed,
      );
    },
  );

  test(
    'ongoing event with hasMatchResults=true and matchResultsViewedAt non-null returns resultsViewed',
    () {
      final event = makeEvent(status: 'ongoing', endTime: futureEnd);
      final application = makeApplication(
        event: event,
        matchResultsViewedAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(
        resolve(application: application, hasMatchResults: true),
        EventLifecyclePhase.resultsViewed,
      );
    },
  );

  test(
    'isCheckedIn=true, hasMatchingCandidates=true, hasSubmittedVotes=true returns matching',
    () {
      final event = makeEvent(status: 'ongoing', endTime: futureEnd);
      final application = makeApplication(event: event);
      expect(
        resolve(
          application: application,
          isCheckedIn: true,
          hasMatchingCandidates: true,
          hasSubmittedVotes: true,
        ),
        EventLifecyclePhase.matching,
      );
    },
  );

  test(
    'isCheckedIn=true, hasMatchingCandidates=true, hasSubmittedVotes=false returns matchingReady',
    () {
      final event = makeEvent(status: 'ongoing', endTime: futureEnd);
      final application = makeApplication(event: event);
      expect(
        resolve(
          application: application,
          isCheckedIn: true,
          hasMatchingCandidates: true,
        ),
        EventLifecyclePhase.matchingReady,
      );
    },
  );

  test(
    'isCheckedIn=true with event.status==ongoing and no candidates returns checkedIn',
    () {
      final event = makeEvent(status: 'ongoing', endTime: futureEnd);
      final application = makeApplication(event: event);
      expect(
        resolve(application: application, isCheckedIn: true),
        EventLifecyclePhase.checkedIn,
      );
    },
  );

  test(
    'isCheckedIn=true with event.status!=ongoing returns checkedIn',
    () {
      // Use a future startTime so !now.isBefore(startTime) is false,
      // ensuring no checkInWindow path; status not 'ongoing'/'active'
      final event = makeEvent(
        status: 'scheduled',
        startTime: now.add(const Duration(hours: 2)),
        endTime: futureEnd,
      );
      final application = makeApplication(event: event);
      expect(
        resolve(application: application, isCheckedIn: true),
        EventLifecyclePhase.checkedIn,
      );
    },
  );

  test(
    'event.status==active (isCheckInWindow) returns checkInReady',
    () {
      // status='active' triggers isCheckInWindow; startTime in future so
      // !now.isBefore(startTime) is false, but status alone is sufficient
      final event = makeEvent(
        status: 'active',
        startTime: now.add(const Duration(hours: 1)),
        endTime: futureEnd,
      );
      final application = makeApplication(event: event);
      expect(
        resolve(application: application),
        EventLifecyclePhase.checkInReady,
      );
    },
  );

  test(
    'future event with status=scheduled and no active conditions returns waiting',
    () {
      final event = makeEvent(
        status: 'scheduled',
        startTime: now.add(const Duration(hours: 2)),
        endTime: futureEnd,
      );
      final application = makeApplication(event: event);
      expect(
        resolve(application: application),
        EventLifecyclePhase.waiting,
      );
    },
  );
}
