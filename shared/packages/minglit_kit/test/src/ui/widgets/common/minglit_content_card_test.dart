import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitContentCard', () {
    testWidgets('renders with required params only', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitContentCard(child: Text('content'))),
      );

      expect(find.text('content'), findsOneWidget);
      expect(find.byType(MinglitContentCard), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentCard(
            child: Column(
              children: [
                Text('first'),
                Text('second'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('renders with empty content child', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitContentCard(child: SizedBox.shrink())),
      );

      expect(find.byType(MinglitContentCard), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(24);

      await tester.pumpWidget(
        wrap(
          const MinglitContentCard(
            padding: customPadding,
            child: Text('padded'),
          ),
        ),
      );

      expect(find.text('padded'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          MinglitContentCard(
            onTap: () => tapped = true,
            child: const Text('tappable'),
          ),
        ),
      );

      await tester.tap(find.text('tappable'));
      expect(tapped, isTrue);
    });

    testWidgets('wraps with InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitContentCard(
            onTap: () {},
            child: const Text('tappable'),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not use InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitContentCard(child: Text('static'))),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('renders highlighted border when highlighted is true',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitContentCard(
            highlighted: true,
            child: Text('highlighted'),
          ),
        ),
      );

      expect(find.text('highlighted'), findsOneWidget);
      expect(find.byType(MinglitContentCard), findsOneWidget);
    });
  });
}
