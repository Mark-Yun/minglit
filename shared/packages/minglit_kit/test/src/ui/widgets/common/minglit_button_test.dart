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

    // Fix #1374: Regression tests — buttons must use theme colorScheme, not hardcoded colors
    testWidgets('primary button uses colorScheme.primary background', (
      tester,
    ) async {
      const lightPrimary = Color(0xFF9900FF);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: lightPrimary),
          ),
          home: Scaffold(
            body: MinglitButton(label: '테마 테스트', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!;
      final bg = style.backgroundColor?.resolve({});
      expect(bg, lightPrimary);
    });

    testWidgets('secondary button uses colorScheme.primary for border', (
      tester,
    ) async {
      const testPrimary = Color(0xFF1234AB);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: testPrimary),
          ),
          home: Scaffold(
            body: MinglitButton.secondary(label: '보더 테스트', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final side = button.style!.side?.resolve({});
      expect(side?.color, testPrimary);
    });

    testWidgets('text button uses colorScheme.primary foreground', (
      tester,
    ) async {
      const testPrimary = Color(0xFF00A3FF);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: testPrimary),
          ),
          home: Scaffold(
            body: MinglitButton.text(label: '텍스트 색상', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      final fg = button.style!.foregroundColor?.resolve({});
      expect(fg, testPrimary);
    });

    testWidgets('dark mode: primary button adapts to dark theme color', (
      tester,
    ) async {
      const darkPrimary = Color(0xFFAA33FF);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(primary: darkPrimary),
          ),
          home: Scaffold(
            body: MinglitButton(label: '다크모드', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final bg = button.style!.backgroundColor?.resolve({});
      expect(bg, darkPrimary);
    });

    // Fix #1383: destructive variant tests
    testWidgets('destructive renders ElevatedButton', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton.destructive(label: '삭제', onPressed: () {}),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('destructive uses colorScheme.error background', (
      tester,
    ) async {
      // Use a custom color distinct from Flutter's default error color to
      // verify the button reads from colorScheme.error, not a hardcoded value.
      const testError = Color(0xFF990000);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(error: testError),
          ),
          home: Scaffold(
            body: MinglitButton.destructive(label: '탈퇴', onPressed: () {}),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final bg = button.style!.backgroundColor?.resolve({});
      expect(bg, testError);
    });

    testWidgets('destructive is disabled when onPressed is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitButton.destructive(label: '삭제'),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('destructive calls onPressed when tapped', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        buildApp(
          MinglitButton.destructive(
            label: '탈퇴하기',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.text('탈퇴하기'));
      expect(pressed, isTrue);
    });

    testWidgets('destructive shows loading indicator when isLoading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          MinglitButton.destructive(
            label: '삭제',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'destructive loading spinner uses colorScheme.onError color',
      (tester) async {
        // Use custom colors distinct from Material defaults to verify the spinner
        // reads colorScheme.onError (not hardcoded) and background reads colorScheme.error.
        const testError = Color(0xFF990000);
        const testOnError = Color(0xFFEEEEEE);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                error: testError,
                onError: testOnError,
              ),
            ),
            home: Scaffold(
              body: MinglitButton.destructive(
                label: '삭제',
                onPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        );

        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.color, testOnError);
      },
    );
  });
}
