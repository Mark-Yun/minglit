import 'package:app_partner/src/features/party/event/edit/event_edit_controller.dart';
import 'package:app_partner/src/features/party/event/edit/event_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

class _FakeEventEditController extends EventEditController {
  _FakeEventEditController(this._state);

  final EventEditState _state;

  @override
  Future<EventEditState> build(String eventId) async => _state;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  const eventId = 'event-1';

  Event baseEvent() {
    final now = DateTime(2026, 5, 6, 19);
    return Event(
      id: eventId,
      partyId: 'party-1',
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
      title: '테스트 이벤트',
    );
  }

  Widget buildSubject(EventEditState state) {
    return ProviderScope(
      overrides: [
        eventEditControllerProvider(eventId).overrideWith(
          () => _FakeEventEditController(state),
        ),
      ],
      child: const MaterialApp(home: EventEditPage(eventId: eventId)),
    );
  }

  testWidgets(
    'locked state shows lock banner when confirmedCount >= 1',
    (tester) async {
      final state = createEventEditState(
        event: baseEvent(),
        confirmedCount: 2,
        title: '테스트 이벤트',
        startTime: DateTime(2026, 5, 6, 19),
        endTime: DateTime(2026, 5, 6, 21),
        maxParticipants: 20,
        location: '강남',
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      expect(find.textContaining('확정 참가자 2명'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    },
  );

  testWidgets(
    'unlocked state has no lock banner when confirmedCount == 0',
    (tester) async {
      final state = createEventEditState(
        event: baseEvent(),
        confirmedCount: 0,
        title: '테스트 이벤트',
        startTime: DateTime(2026, 5, 6, 19),
        endTime: DateTime(2026, 5, 6, 21),
        maxParticipants: 20,
        location: '강남',
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.textContaining('확정 참가자'), findsNothing);
    },
  );

  testWidgets('save button disabled when no changes', (tester) async {
    final state = createEventEditState(
      event: baseEvent(),
      confirmedCount: 0,
      title: '테스트 이벤트',
      startTime: DateTime(2026, 5, 6, 19),
      endTime: DateTime(2026, 5, 6, 21),
      maxParticipants: 20,
      location: null,
    );

    await tester.pumpWidget(buildSubject(state));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('save button enabled when isDirty=true', (tester) async {
    // Fix #2110: regression guard — isDirty=true must enable the save button.
    // This prevents _computeIsDirty from silently always returning false.
    final state = createEventEditState(
      event: baseEvent(),
      confirmedCount: 0,
      title: '변경된 제목',
      startTime: DateTime(2026, 5, 6, 19),
      endTime: DateTime(2026, 5, 6, 21),
      maxParticipants: 20,
      location: null,
      isDirty: true,
    );

    await tester.pumpWidget(buildSubject(state));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    'save with confirmed participants and schedule change shows reason dialog',
    (tester) async {
      // Fix #2110: spec §Lock Policy — schedule change + confirmedCount >= 1
      // must trigger reason dialog before submit.
      final event = baseEvent();
      final changedStartTime = event.startTime.add(const Duration(days: 1));
      final state = createEventEditState(
        event: event,
        confirmedCount: 2,
        title: event.title ?? '',
        startTime: changedStartTime, // schedule changed
        endTime: changedStartTime.add(const Duration(hours: 2)),
        maxParticipants: 20,
        location: null,
        isDirty: true,
      );

      await tester.pumpWidget(buildSubject(state));
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('일정 변경 사유'), findsOneWidget);
    },
  );
}
