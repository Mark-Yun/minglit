import 'dart:async';

import 'package:app_user/src/features/event/matching/ui/event_matching_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  const eventId = 'event-1';
  late MockMatchingRepository mockMatchingRepository;

  setUp(() {
    mockMatchingRepository = MockMatchingRepository();
    when(
      () => mockMatchingRepository.commitMatchLikes(
        eventId: any(named: 'eventId'),
        candidateIds: any(named: 'candidateIds'),
      ),
    ).thenAnswer((_) async {});
  });

  Event buildEvent({String status = 'ongoing'}) {
    final now = DateTime(2026, 5, 5, 20);
    return Event(
      id: eventId,
      partyId: 'party-1',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
      title: '강남 네트워킹',
      status: status,
    );
  }

  List<UserProfile> buildCandidates() => const [
    UserProfile(id: 'candidate-1', name: '가은', username: 'gaeun'),
    UserProfile(id: 'candidate-2', name: '나래', username: 'narae'),
    UserProfile(id: 'candidate-3', name: '다은', username: 'daeun'),
  ];

  Widget buildSubject({
    AsyncValue<Event>? eventValue,
    AsyncValue<List<UserProfile>>? candidatesValue,
  }) {
    final eventOverride = eventValue;
    final candidatesOverride = candidatesValue;

    return ProviderScope(
      overrides: [
        matchingRepositoryProvider.overrideWithValue(mockMatchingRepository),
        if (eventOverride != null)
          eventDetailProvider(
            eventId,
          ).overrideWith((_) async => eventOverride.requireValue),
        if (candidatesOverride != null)
          matchCandidatesProvider(
            eventId,
          ).overrideWith((_) async => candidatesOverride.requireValue),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const EventMatchingScreen(eventId: eventId),
      ),
    );
  }

  testWidgets(
    'Loading: shows 6 skeleton rows (4 skeletons each) while data is pending',
    (
      tester,
    ) async {
      final eventCompleter = Completer<Event>();
      final candidatesCompleter = Completer<List<UserProfile>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(
              mockMatchingRepository,
            ),
            eventDetailProvider(
              eventId,
            ).overrideWith((_) => eventCompleter.future),
            matchCandidatesProvider(eventId).overrideWith(
              (_) => candidatesCompleter.future,
            ),
          ],
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: const EventMatchingScreen(eventId: eventId),
          ),
        ),
      );

      expect(find.byType(MinglitSkeleton), findsNWidgets(24));
    },
  );

  testWidgets('Default: renders unselected candidates and disabled CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        eventValue: AsyncData(buildEvent()),
        candidatesValue: AsyncData(buildCandidates()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('가은'), findsOneWidget);
    expect(find.text('나래'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '확인'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Selecting: up to 3 candidates can be selected and CTA updates', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        eventValue: AsyncData(buildEvent()),
        candidatesValue: AsyncData(buildCandidates()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가은'));
    await tester.pump();
    await tester.tap(find.text('나래'));
    await tester.pump();

    expect(find.text('2명 선택됨'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '확인 (2명)'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '확인 (2명)'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Confirm Dialog: tapping CTA shows confirm dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        eventValue: AsyncData(buildEvent()),
        candidatesValue: AsyncData(buildCandidates()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가은'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, '확인 (1명)'));
    await tester.pumpAndSettle();

    expect(find.text('1명에게 좋아요를 보낼게요'), findsOneWidget);
    expect(find.text('보내기'), findsOneWidget);
  });

  testWidgets(
    'Submitted: successful commit replaces screen with confirmation page',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          eventValue: AsyncData(buildEvent()),
          candidatesValue: AsyncData(buildCandidates()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('가은'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '확인 (1명)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('보내기'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('좋아요를 보냈어요'), findsOneWidget);
      verify(
        () => mockMatchingRepository.commitMatchLikes(
          eventId: eventId,
          candidateIds: ['candidate-1'],
        ),
      ).called(1);
    },
  );

  testWidgets('Ended: completed event shows privacy lock state', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        eventValue: AsyncData(buildEvent(status: 'completed')),
        candidatesValue: AsyncData(buildCandidates()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('매칭 선택이 종료되었어요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    expect(find.text('가은'), findsNothing);
  });

  testWidgets('Empty: no candidates shows empty state', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        eventValue: AsyncData(buildEvent()),
        candidatesValue: const AsyncData(<UserProfile>[]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지금은 선택할 후보가 없어요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });
}
