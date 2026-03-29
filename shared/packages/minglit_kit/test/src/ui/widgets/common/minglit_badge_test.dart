import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_badge.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitBadge', () {
    testWidgets('renders with label and color', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitBadge(label: '승인됨', color: Colors.green)),
      );

      expect(find.text('승인됨'), findsOneWidget);
      expect(find.byType(MinglitBadge), findsOneWidget);
    });

    testWidgets('compact variant renders smaller padding', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            children: [
              MinglitBadge(
                label: 'default',
                color: Colors.blue,
              ),
              MinglitBadge(
                label: 'compact',
                color: Colors.blue,
                compact: true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('default'), findsOneWidget);
      expect(find.text('compact'), findsOneWidget);

      // Compact badge should be smaller than default
      final defaultSize = tester.getSize(find.text('default'));
      final compactSize = tester.getSize(find.text('compact'));

      // Compact uses labelSmall, default uses labelMedium — compact text
      // should have a smaller or equal height
      expect(compactSize.height, lessThanOrEqualTo(defaultSize.height));
    });

    testWidgets('renders with different colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            children: [
              MinglitBadge(label: '에러', color: Colors.red),
              MinglitBadge(label: '성공', color: Colors.green),
              MinglitBadge(label: '대기', color: Colors.orange),
            ],
          ),
        ),
      );

      expect(find.text('에러'), findsOneWidget);
      expect(find.text('성공'), findsOneWidget);
      expect(find.text('대기'), findsOneWidget);

      // Verify each badge has distinct background color via DecoratedBox
      final decoratedBoxes =
          tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      final colors = <Color>{};
      for (final box in decoratedBoxes) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          colors.add(decoration.color!);
        }
      }
      // At least 3 distinct colors (one per badge)
      expect(colors.length, greaterThanOrEqualTo(3));
    });

    testWidgets('text is findable by semantics', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitBadge(label: '심사중', color: Colors.blue)),
      );

      // Text widget provides implicit semantics
      expect(
        find.bySemanticsLabel('심사중'),
        findsOneWidget,
      );
    });

    testWidgets('default compact is false', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitBadge(label: 'test', color: Colors.blue)),
      );

      final badge =
          tester.widget<MinglitBadge>(find.byType(MinglitBadge));
      expect(badge.compact, isFalse);
    });

    testWidgets('uses DecoratedBox with rounded corners', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitBadge(label: 'badge', color: Colors.purple)),
      );

      final decoratedBox =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
      final decoration = decoratedBox.decoration as BoxDecoration;

      expect(decoration.borderRadius, isNotNull);
      expect(decoration.color, isNotNull);
    });
  });
}
