import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('MinglitContentCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentCard(child: Text('카드 내용')),
        ),
      );

      expect(find.text('카드 내용'), findsOneWidget);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          MinglitContentCard(
            onTap: () => tapped = true,
            child: const Text('탭 가능'),
          ),
        ),
      );

      await tester.tap(find.text('탭 가능'));
      expect(tapped, isTrue);
    });

    testWidgets('wraps in InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitContentCard(
            onTap: () {},
            child: const Text('내용'),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not wrap in InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentCard(child: Text('내용')),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('applies highlighted border when highlighted is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentCard(
            highlighted: true,
            child: Text('강조'),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      // Highlighted border should use primary color (not outlineVariant)
      final theme = Theme.of(tester.element(find.text('강조')));
      expect(border.top.color, theme.colorScheme.primary);
    });
  });
}
