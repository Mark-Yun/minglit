import 'dart:async';

import 'package:app_partner/src/features/party/event/review/event_application_review_carousel_page.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

EventApplication _makeApplication({
  required String id,
  String status = 'pending_review',
}) {
  final now = DateTime(2026, 5, 10, 20);
  return EventApplication(
    id: id,
    eventId: 'event_1',
    ticketId: 'ticket_1',
    userId: 'user_$id',
    status: status,
    createdAt: now,
    updatedAt: now,
    // Fix #2126: PM #1141 — username displayed instead of name in carousel
    user: UserProfile(
      id: 'user_$id',
      name: '실명$id',
      username: '닉네임$id',
      birthYear: 1995,
    ),
  );
}

class _FakeReviewController extends EventApplicationReviewController {
  static final List<({String applicationId, String status, String? reason})>
  calls = [];

  static void reset() => calls.clear();

  @override
  FutureOr<void> build() {}

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? reason,
  }) async {
    calls.add((applicationId: applicationId, status: status, reason: reason));
  }
}

void main() {
  setUp(() {
    _FakeReviewController.reset();
  });

  Widget buildPage(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: EventApplicationReviewCarouselPage(
          partyId: 'party_1',
          eventId: 'event_1',
        ),
      ),
    );
  }

  testWidgets('empty queue shows empty state', (tester) async {
    final container = ProviderContainer(
      overrides: [
        carouselQueueProvider(
          'event_1',
          null,
        ).overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    expect(find.text('심사 대기 중인 신청이 없습니다.'), findsOneWidget);
  });

  testWidgets('approve marks locally without server call', (tester) async {
    final queue = [_makeApplication(id: 'app_1')];
    final container = ProviderContainer(
      overrides: [
        carouselQueueProvider(
          'event_1',
          null,
        ).overrideWith((ref) async => queue),
        eventApplicationReviewControllerProvider.overrideWith(
          _FakeReviewController.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    await tester.tap(find.text('승인'));
    await tester.pump();

    final marks = container.read(reviewMarkingsProvider);
    expect(marks['app_1']?.status, 'approved');
    expect(marks['app_1']?.reason, isNull);
    expect(_FakeReviewController.calls, isEmpty);
  });

  testWidgets('reject with reason marks locally', (tester) async {
    final queue = [_makeApplication(id: 'app_1')];
    final container = ProviderContainer(
      overrides: [
        carouselQueueProvider(
          'event_1',
          null,
        ).overrideWith((ref) async => queue),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '조건 불충분');
    await tester.tap(find.text('거절 확인'));
    await tester.pump();

    final marks = container.read(reviewMarkingsProvider);
    expect(marks['app_1']?.status, 'rejected');
    expect(marks['app_1']?.reason, '조건 불충분');
  });

  testWidgets(
    'dismiss reject sheet without confirming does not mark application',
    (tester) async {
      final queue = [_makeApplication(id: 'app_1')];
      final container = ProviderContainer(
        overrides: [
          carouselQueueProvider(
            'event_1',
            null,
          ).overrideWith((ref) async => queue),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(buildPage(container));
      await tester.pump();

      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();

      // Dismiss sheet by tapping outside (barrier)
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();

      // Fix #2272: sheet dismissed (null returned) → no marking should occur
      final marks = container.read(reviewMarkingsProvider);
      expect(marks, isEmpty);
    },
  );

  testWidgets('empty queue does not show progress text', (tester) async {
    final container = ProviderContainer(
      overrides: [
        carouselQueueProvider(
          'event_1',
          null,
        ).overrideWith((ref) async => const []),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    // Fix #2272: empty queue must not show "1 / 0"
    expect(find.textContaining('/ 0'), findsNothing);
  });

  testWidgets('startApplicationId positions carousel at correct card', (
    tester,
  ) async {
    final queue = [
      _makeApplication(id: 'app_1'),
      _makeApplication(id: 'app_2'),
      _makeApplication(id: 'app_3'),
    ];
    final container = ProviderContainer(
      overrides: [
        carouselQueueProvider(
          'event_1',
          null,
        ).overrideWith((ref) async => queue),
      ],
    );
    addTearDown(container.dispose);

    // Fix #2272: startApplicationId should position at index 1 (app_2)
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: EventApplicationReviewCarouselPage(
            partyId: 'party_1',
            eventId: 'event_1',
            startApplicationId: 'app_2',
          ),
        ),
      ),
    );
    await tester.pump();

    // Progress counter should show "2 / 3" (index 1 = 2nd card)
    expect(find.text('2 / 3'), findsOneWidget);
    // Fix #2126: PM #1141 — username (닉네임) displayed, not actual name
    expect(find.text('닉네임app_2'), findsOneWidget);
  });

  testWidgets('shows 모든 신청 검토 완료 after last mark', (tester) async {
    final queue = [_makeApplication(id: 'app_1')];
    final container = ProviderContainer(
      overrides: [
        carouselQueueProvider(
          'event_1',
          null,
        ).overrideWith((ref) async => queue),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    await tester.tap(find.text('승인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('모든 신청 검토 완료'), findsOneWidget);
    expect(find.text('최종 확인 화면으로 이동합니다…'), findsOneWidget);
  });
}
