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

      expect(find.textContaining('확정 참가자 2명이 있어'), findsOneWidget);
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
      expect(find.textContaining('일정·장소 변경 시 알림'), findsNothing);
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
}
