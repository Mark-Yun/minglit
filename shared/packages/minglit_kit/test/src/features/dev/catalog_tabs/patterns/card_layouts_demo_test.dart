import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/card_layouts_demo.dart';

void main() {
  group('CardLayoutsDemo', () {
    Widget buildSubject() => const MaterialApp(home: CardLayoutsDemo());

    testWidgets('data state shows 5 card variant titles', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Image Card'), findsOneWidget);
      expect(find.text('Transaction Card'), findsOneWidget);
      expect(find.text('Info Card'), findsOneWidget);
      // Stats Card and Selectable Card may be below initial viewport — scroll to them
      await tester.scrollUntilVisible(
        find.text('Stats Card'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Stats Card'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Selectable Card'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Selectable Card'), findsOneWidget);
    });

    testWidgets('switches to loading state — no card variant titles shown', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Loading'));
      await tester.pump();

      expect(find.text('Image Card'), findsNothing);
      expect(find.text('Transaction Card'), findsNothing);
      expect(find.text('Info Card'), findsNothing);
      expect(find.text('Stats Card'), findsNothing);
      expect(find.text('Selectable Card'), findsNothing);
    });

    testWidgets('switches to error state — MinglitErrorState shown', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Error'));
      await tester.pump();

      expect(find.text('카드 데이터를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('switches to empty state — MinglitEmptyState shown', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Empty'));
      await tester.pump();

      expect(find.text('표시할 카드가 없습니다'), findsOneWidget);
    });

    testWidgets('selectable card toggles on tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Scroll to Selectable Card (may be below initial viewport)
      await tester.scrollUntilVisible(
        find.text('Selectable Card'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Selectable Card'), findsOneWidget);

      // Find and tap the selectable card content (the card body text)
      final selectableCardFinder = find.text('브런치 네트워킹');
      expect(selectableCardFinder, findsOneWidget);
      await tester.tap(selectableCardFinder);
      await tester.pump();

      // After tap, the check_circle icon should be visible (selected state)
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap again to deselect
      await tester.tap(selectableCardFinder);
      await tester.pump();

      // After second tap, radio_button_unchecked icon should be visible again
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });
  });
}
