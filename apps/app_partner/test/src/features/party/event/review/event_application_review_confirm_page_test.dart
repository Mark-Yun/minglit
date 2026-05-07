import 'package:app_partner/src/features/party/event/review/event_application_review_confirm_page.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
