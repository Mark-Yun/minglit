import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_tag.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitTag', () {
    testWidgets('renders with label and color', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTag(label: '음악', color: Colors.blue)),
      );

      expect(find.text('음악'), findsOneWidget);
      expect(find.byType(MinglitTag), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitTag(
            label: '카테고리',
            color: Colors.green,
            icon: Icons.category,
          ),
        ),
      );

      expect(find.text('카테고리'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('small size renders smaller than medium', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            children: [
              MinglitTag(
                label: 'medium',
                color: Colors.blue,
              ),
              MinglitTag(
                label: 'small',
                color: Colors.blue,
                size: MinglitTagSize.small,
              ),
            ],
          ),
        ),
      );

      final mediumSize = tester.getSize(find.byType(MinglitTag).first);
      final smallSize = tester.getSize(find.byType(MinglitTag).last);

      expect(smallSize.height, lessThan(mediumSize.height));
    });

    testWidgets('renders with different colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          const Row(
            children: [
              MinglitTag(label: '빨강', color: Colors.red),
              MinglitTag(label: '파랑', color: Colors.blue),
              MinglitTag(label: '초록', color: Colors.green),
            ],
          ),
        ),
      );

      expect(find.text('빨강'), findsOneWidget);
      expect(find.text('파랑'), findsOneWidget);
      expect(find.text('초록'), findsOneWidget);

      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final colors = <Color>{};
      for (final box in decoratedBoxes) {
        final decoration = box.decoration;
        if (decoration is BoxDecoration && decoration.color != null) {
          colors.add(decoration.color!);
        }
      }
      expect(colors.length, greaterThanOrEqualTo(3));
    });

    testWidgets('default size is medium', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTag(label: 'test', color: Colors.blue)),
      );

      final tag = tester.widget<MinglitTag>(find.byType(MinglitTag));
      expect(tag.size, MinglitTagSize.medium);
    });

    testWidgets('is not interactive (no InkWell)', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTag(label: 'readonly', color: Colors.blue)),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('uses pill-shaped border radius', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTag(label: 'pill', color: Colors.purple)),
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;

      expect(decoration.borderRadius, isNotNull);
      expect(decoration.color, isNotNull);
    });

    testWidgets('text is findable by semantics', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitTag(label: '상태', color: Colors.orange)),
      );

      expect(find.bySemanticsLabel('상태'), findsOneWidget);
    });
  });
}
