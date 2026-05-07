import 'dart:async';

import 'package:app_partner/src/features/party/event/review/event_application_review_confirm_page.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PartialFailController extends EventApplicationReviewController {
  final int _failAtIndex;
  int _callCount = 0;
  final List<String> submitted = [];

  _PartialFailController(this._failAtIndex);

  @override
  FutureOr<void> build() {}

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? reason,
  }) async {
    if (_callCount == _failAtIndex) {
      _callCount++;
      throw Exception('서버 오류');
    }
    submitted.add(applicationId);
    _callCount++;
  }
}

void main() {
  Widget buildPage(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: EventApplicationReviewConfirmPage(eventId: 'event_1'),
      ),
    );
  }

  testWidgets('shows correct summary counts', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(reviewMarkingsProvider.notifier);
    notifier.addMark('app_1', 'approved');
    notifier.addMark('app_2', 'approved');
    notifier.addMark('app_3', 'rejected', reason: '사유');

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    expect(find.text('2건'), findsOneWidget);
    expect(find.text('1건'), findsOneWidget);
  });

  testWidgets('submit button is disabled when no marks', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('submit button shows correct count label', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(reviewMarkingsProvider.notifier);
    notifier.addMark('app_1', 'approved');
    notifier.addMark('app_2', 'approved');
    notifier.addMark('app_3', 'rejected', reason: '사유');

    await tester.pumpWidget(buildPage(container));
    await tester.pump();

    expect(find.text('3건 최종 제출'), findsOneWidget);
  });

  // Fix #2272: partial failure regression — app_1 succeeds then app_2 fails.
  // On retry, only app_2 should be re-submitted (app_1 must not be re-sent).
  testWidgets(
    'partial submit failure — already-committed marks removed immediately',
    (tester) async {
      // Controller fails on second call (index 1 = app_2)
      final controller = _PartialFailController(1);
      final container = ProviderContainer(
        overrides: [
          eventApplicationReviewControllerProvider.overrideWith(
            () => controller,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(reviewMarkingsProvider.notifier);
      // Use addMark so marks are ordered consistently
      notifier.addMark('app_1', 'approved');
      notifier.addMark('app_2', 'rejected');

      await tester.pumpWidget(buildPage(container));
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump(); // submit starts

      // Wait for async operations to complete
      await tester.pumpAndSettle();

      // app_1 was submitted successfully and must have been removed from marks.
      // app_2 failed and must still be present for retry.
      final remaining = container.read(reviewMarkingsProvider);
      expect(remaining.containsKey('app_1'), isFalse);
      expect(remaining.containsKey('app_2'), isTrue);
    },
  );
}
