import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_button.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MinglitButton', () {
    testWidgets('primary renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton(label: '참가하기', onPressed: () {}),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('참가하기'), findsOneWidget);
    });

    testWidgets('secondary renders OutlinedButton', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton.secondary(label: '취소', onPressed: () {}),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('text renders TextButton', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton.text(label: '더보기', onPressed: () {}),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitButton(label: 'Disabled'),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton(
            label: '저장',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Button should be disabled during loading
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton(
            label: '다음',
            icon: Icons.arrow_forward,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('expand=true makes button full width', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton(label: '전체 너비', onPressed: () {}),
        ),
      );

      // Primary defaults to expand=true, wrapped in SizedBox(infinity)
      expect(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == double.infinity,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('text variant defaults to expand=false', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton.text(label: '텍스트', onPressed: () {}),
        ),
      );

      // Text variant defaults to expand=false, no SizedBox wrapper
      expect(
        find.ancestor(
          of: find.byType(TextButton),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == double.infinity,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildApp(
          MinglitButton(
            label: '탭 테스트',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.text('탭 테스트'));
      expect(pressed, isTrue);
    });

    testWidgets('small size renders smaller button', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton(
            label: '작은 버튼',
            size: MinglitButtonSize.small,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('작은 버튼'), findsOneWidget);
    });
  });
}
