import 'dart:async';

import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockMatchingRepository mockMatchingRepo;
  late MockUser mockUser;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockMatchingRepo = MockMatchingRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_123');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.userMetadata).thenReturn({});
  });

  TodayActiveEvent makeActiveEvent({
    String id = 'event_1',
    String title = '강남 밍릿파티',
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
        title: title,
        startTime: startTime ?? now.add(const Duration(hours: 2)),
        endTime: endTime ?? now.add(const Duration(hours: 5)),
        createdAt: now,
        updatedAt: now,
        status: status,
      ),
      participantStatus: participantStatus,
    );
  }

  /// Stubs matching repository to throw (matching not available).
  void stubMatchingNotAvailable(String eventId) {
    when(
      () => mockMatchingRepo.getMatchingCandidates(eventId),
    ).thenAnswer((_) async => throw Exception('not available'));
    when(
      () => mockMatchingRepo.getMyMatches(eventId),
    ).thenAnswer((_) async => throw Exception('not available'));
  }

  Widget createTestWidget({
    required List<TodayActiveEvent> activeEvents,
    VoidCallback? onTap,
    bool throwError = false,
  }) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
        matchingRepositoryProvider.overrideWith((ref) => mockMatchingRepo),
        todayActiveEventsProvider.overrideWith((ref) {
          if (throwError) throw Exception('Network error');
          return activeEvents;
        }),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomSheet: EventNowBar(onTap: onTap),
        ),
      ),
    );
  }

  group('EventNowBar', () {
    testWidgets(
      'renders bar with event name and status when active event exists',
      (tester) async {
        stubMatchingNotAvailable('event_1');

        await tester.pumpWidget(
          createTestWidget(activeEvents: [makeActiveEvent()]),
        );
        await tester.pumpAndSettle();

        expect(find.text('강남 밍릿파티'), findsOneWidget);
        expect(find.text('곧 시작'), findsOneWidget);
      },
    );

    testWidgets('hidden (SizedBox.shrink) when no active events', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(activeEvents: []));
      await tester.pumpAndSettle();

      expect(find.text('곧 시작'), findsNothing);
      expect(find.text('체크인하세요'), findsNothing);
    });

    testWidgets('shows CHECK_IN_READY status text when start time has passed', (
      tester,
    ) async {
      final event = makeActiveEvent(
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      stubMatchingNotAvailable('event_1');

      await tester.pumpWidget(createTestWidget(activeEvents: [event]));
      await tester.pumpAndSettle();

      expect(find.text('체크인하세요'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('event name is truncated with ellipsis for long names', (
      tester,
    ) async {
      const longName = '아주 긴 이벤트 이름으로 테스트하는 매우 매우 길고 긴 강남 밍릿파티 이벤트 제목입니다';
      final event = makeActiveEvent(title: longName);
      stubMatchingNotAvailable('event_1');

      await tester.pumpWidget(createTestWidget(activeEvents: [event]));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text(longName));
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('shows CHECKED_IN status text after check-in', (tester) async {
      final event = makeActiveEvent(participantStatus: 'checked_in');
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => throw Exception('not available'));

      await tester.pumpWidget(createTestWidget(activeEvents: [event]));
      await tester.pumpAndSettle();

      expect(find.text('체크인 완료'), findsOneWidget);
    });

    testWidgets('shows time until start for WAITING state', (tester) async {
      final event = makeActiveEvent(
        startTime: DateTime.now().add(const Duration(minutes: 45)),
      );
      stubMatchingNotAvailable('event_1');

      await tester.pumpWidget(createTestWidget(activeEvents: [event]));
      await tester.pumpAndSettle();

      expect(find.text('곧 시작'), findsOneWidget);
      // Trailing shows "N분 후" for waiting state (< 60 min)
      expect(find.textContaining('분 후'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('responds to tap gesture', (tester) async {
      var tapped = false;
      final event = makeActiveEvent();
      stubMatchingNotAvailable('event_1');

      await tester.pumpWidget(
        createTestWidget(
          activeEvents: [event],
          onTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('강남 밍릿파티'));
      expect(tapped, isTrue);
    });

    testWidgets('shows skeleton loading while fetching events', (
      tester,
    ) async {
      // Use a Completer to keep the provider in loading state.
      final completer = Completer<List<TodayActiveEvent>>();
      addTearDown(() {
        if (!completer.isCompleted) completer.complete([]);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayActiveEventsProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: const Scaffold(
              body: SizedBox.expand(),
              bottomSheet: EventNowBar(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitSkeleton), findsOneWidget);

      // Complete future and pump to clean up pending animations.
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows offline bar on error', (tester) async {
      await tester.pumpWidget(
        createTestWidget(activeEvents: [], throwError: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('(오프라인)'), findsOneWidget);
    });

    testWidgets('shows ENDED status for completed event', (tester) async {
      final event = makeActiveEvent(status: 'completed');
      when(
        () => mockMatchingRepo.getMatchingCandidates('event_1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockMatchingRepo.getMyMatches('event_1'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(activeEvents: [event]));
      await tester.pumpAndSettle();

      expect(find.text('종료됨'), findsOneWidget);
    });
  });
}
