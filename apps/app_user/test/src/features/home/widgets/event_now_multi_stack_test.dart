import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_multi_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockMatchingRepository mockMatchingRepo;

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
  });

  /// Helper to create a [TodayActiveEvent] with sensible defaults.
  TodayActiveEvent makeActiveEvent({
    String id = 'event_1',
    String? title,
    String status = 'scheduled',
    String participantStatus = 'ticket_issued',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final now = DateTime.now();
    return TodayActiveEvent(
      event: Event(
        id: id,
        partyId: 'party_1',
        startTime: startTime ?? now.subtract(const Duration(hours: 1)),
        endTime: endTime ?? now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
        status: status,
        title: title ?? '이벤트 $id',
      ),
      participantStatus: participantStatus,
    );
  }

  // ──────────────────────────────────────────────────
  // Sorting logic unit tests (5건)
  // ──────────────────────────────────────────────────
  group('sortActiveEvents — 정렬 로직', () {
    test('진행 중 이벤트가 대기 이벤트보다 우선', () {
      final waiting = makeActiveEvent(id: 'waiting');
      final checkIn = makeActiveEvent(id: 'checkin');

      final stateMap = {
        'waiting': EventNowBarState.waiting,
        'checkin': EventNowBarState.checkInReady,
      };

      final sorted = sortActiveEvents([waiting, checkIn], stateMap);

      expect(sorted.first.event.id, 'checkin');
      expect(sorted.last.event.id, 'waiting');
    });

    test('종료 이벤트가 스택 하단에 위치', () {
      final ended = makeActiveEvent(id: 'ended');
      final waiting = makeActiveEvent(id: 'waiting');
      final active = makeActiveEvent(id: 'active');

      final stateMap = {
        'ended': EventNowBarState.ended,
        'waiting': EventNowBarState.waiting,
        'active': EventNowBarState.matching,
      };

      final sorted = sortActiveEvents([ended, waiting, active], stateMap);

      expect(sorted[0].event.id, 'active');
      expect(sorted[1].event.id, 'waiting');
      expect(sorted[2].event.id, 'ended');
    });

    test('같은 우선순위 내 시작 시간 빠른 순 정렬', () {
      final now = DateTime.now();
      final early = makeActiveEvent(
        id: 'early',
        startTime: now.subtract(const Duration(hours: 2)),
      );
      final late_ = makeActiveEvent(
        id: 'late',
        startTime: now.subtract(const Duration(minutes: 30)),
      );

      final stateMap = {
        'early': EventNowBarState.checkedIn,
        'late': EventNowBarState.matching,
      };

      final sorted = sortActiveEvents([late_, early], stateMap);

      // Both are active priority (0), so sort by start time.
      expect(sorted[0].event.id, 'early');
      expect(sorted[1].event.id, 'late');
    });

    test('4가지 상태 혼합 정렬: RESULTS > CHECKED_IN > WAITING > ENDED', () {
      final results = makeActiveEvent(
        id: 'results',
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
      );
      final checkedIn = makeActiveEvent(
        id: 'checkedin',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final waiting = makeActiveEvent(
        id: 'waiting',
        startTime: DateTime.now().add(const Duration(hours: 1)),
      );
      final ended = makeActiveEvent(
        id: 'ended',
        startTime: DateTime.now().subtract(const Duration(hours: 5)),
      );

      final stateMap = {
        'results': EventNowBarState.results,
        'checkedin': EventNowBarState.checkedIn,
        'waiting': EventNowBarState.waiting,
        'ended': EventNowBarState.ended,
      };

      final sorted = sortActiveEvents(
        [ended, waiting, checkedIn, results],
        stateMap,
      );

      // Active group (results, checkedin) sorted by startTime,
      // then waiting, then ended.
      expect(sorted[0].event.id, 'results');
      expect(sorted[1].event.id, 'checkedin');
      expect(sorted[2].event.id, 'waiting');
      expect(sorted[3].event.id, 'ended');
    });

    test('stateMap에 없는 이벤트는 WAITING 그룹으로 분류', () {
      final known = makeActiveEvent(
        id: 'known',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final unknown = makeActiveEvent(
        id: 'unknown',
        startTime: DateTime.now().add(const Duration(hours: 1)),
      );

      final stateMap = {
        'known': EventNowBarState.matching,
        // 'unknown' is not in the map.
      };

      final sorted = sortActiveEvents([unknown, known], stateMap);

      // known (active priority 0) comes before unknown (waiting priority 1).
      expect(sorted[0].event.id, 'known');
      expect(sorted[1].event.id, 'unknown');
    });
  });

  // ──────────────────────────────────────────────────
  // Widget tests (5건)
  // ──────────────────────────────────────────────────
  group('EventNowMultiStack — 위젯', () {
    /// Sets up mocks so that eventNowBarStateProvider resolves to the given state.
    ProviderContainer makeContainer({
      required List<String> eventIds,
      Map<String, List<UserProfile>>? candidatesMap,
      Map<String, List<MatchPair>>? matchesMap,
    }) {
      final overrides = <dynamic>[
        matchingRepositoryProvider.overrideWith((ref) => mockMatchingRepo),
      ];

      for (final id in eventIds) {
        final candidates = candidatesMap?[id] ?? <UserProfile>[];
        when(
          () => mockMatchingRepo.getMatchingCandidates(id),
        ).thenAnswer((_) async => candidates);

        final matches = matchesMap?[id] ?? <MatchPair>[];
        when(
          () => mockMatchingRepo.getMyMatches(id),
        ).thenAnswer((_) async => matches);
      }

      return createContainer(overrides: overrides);
    }

    Widget buildTestWidget({
      required List<TodayActiveEvent> events,
      required ProviderContainer container,
      void Function(TodayActiveEvent)? onEventTap,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: EventNowMultiStack(
              events: events,
              onEventTap: onEventTap,
            ),
          ),
        ),
      );
    }

    testWidgets('이벤트 0건일 때 SizedBox.shrink 렌더링', (tester) async {
      final container = makeContainer(eventIds: []);

      await tester.pumpWidget(
        buildTestWidget(events: [], container: container),
      );

      // SizedBox.shrink has zero size.
      expect(find.byType(EventNowMultiStack), findsOneWidget);
      final size = tester.getSize(find.byType(EventNowMultiStack));
      expect(size, Size.zero);
    });

    testWidgets('이벤트 1건일 때 카운트 배지 없이 바만 표시', (tester) async {
      final event = makeActiveEvent(
        id: 'solo',
        title: '솔로 이벤트',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
      );

      final container = makeContainer(eventIds: ['solo']);

      await tester.pumpWidget(
        buildTestWidget(events: [event], container: container),
      );
      await tester.pumpAndSettle();

      // Title is shown.
      expect(find.text('솔로 이벤트'), findsOneWidget);
      // No expand_more icon (single event).
      expect(find.byIcon(Icons.expand_more), findsNothing);
      // Chevron right is shown (single event trailing).
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('이벤트 2건일 때 카운트 배지 + 드롭다운 아이콘 표시', (tester) async {
      final event1 = makeActiveEvent(
        id: 'e1',
        title: '첫 번째',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      final event2 = makeActiveEvent(
        id: 'e2',
        title: '두 번째',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
      );

      final container = makeContainer(eventIds: ['e1', 'e2']);

      await tester.pumpWidget(
        buildTestWidget(events: [event1, event2], container: container),
      );
      await tester.pumpAndSettle();

      // Count badge showing "2".
      expect(find.text('2'), findsOneWidget);
      // Dropdown icon is shown.
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      // No chevron right in multi mode.
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('드롭다운 탭 시 이벤트 목록 바텀시트 표시', (tester) async {
      final event1 = makeActiveEvent(
        id: 'e1',
        title: '첫 번째 이벤트',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      final event2 = makeActiveEvent(
        id: 'e2',
        title: '두 번째 이벤트',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
      );

      final container = makeContainer(eventIds: ['e1', 'e2']);

      await tester.pumpWidget(
        buildTestWidget(events: [event1, event2], container: container),
      );
      await tester.pumpAndSettle();

      // Tap the dropdown icon.
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Bottom sheet header is shown.
      expect(find.text('진행 중인 이벤트'), findsOneWidget);
      // Both event titles appear in the sheet.
      expect(find.text('첫 번째 이벤트'), findsWidgets);
      expect(find.text('두 번째 이벤트'), findsOneWidget);
    });

    testWidgets('바텀시트에서 이벤트 선택 시 onEventTap 콜백 호출', (tester) async {
      final event1 = makeActiveEvent(
        id: 'e1',
        title: '이벤트 A',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 4)),
      );
      final event2 = makeActiveEvent(
        id: 'e2',
        title: '이벤트 B',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        endTime: DateTime.now().add(const Duration(hours: 5)),
      );

      final container = makeContainer(eventIds: ['e1', 'e2']);
      TodayActiveEvent? tappedEvent;

      await tester.pumpWidget(
        buildTestWidget(
          events: [event1, event2],
          container: container,
          onEventTap: (e) => tappedEvent = e,
        ),
      );
      await tester.pumpAndSettle();

      // Open the dropdown.
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Tap '이벤트 B' in the bottom sheet.
      await tester.tap(find.text('이벤트 B'));
      await tester.pumpAndSettle();

      expect(tappedEvent, isNotNull);
      expect(tappedEvent!.event.id, 'e2');
    });
  });
}
