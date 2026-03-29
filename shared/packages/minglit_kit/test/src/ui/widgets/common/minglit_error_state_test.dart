import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_error_state.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitErrorState', () {
    testWidgets('renders with defaults', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitErrorState()),
      );

      expect(find.text('오류가 발생했습니다.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(MinglitErrorState), findsOneWidget);
    });

    testWidgets('renders custom title', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitErrorState(title: '네트워크 오류')),
      );

      expect(find.text('네트워크 오류'), findsOneWidget);
      expect(find.text('오류가 발생했습니다.'), findsNothing);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitErrorState(icon: Icons.wifi_off),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitErrorState(
            subtitle: '인터넷 연결을 확인해주세요',
          ),
        ),
      );

      expect(find.text('인터넷 연결을 확인해주세요'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitErrorState()),
      );

      // Title only (no subtitle text)
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry is provided', (
      tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        wrap(MinglitErrorState(onRetry: () => retried = true)),
      );

      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(retried, isTrue);
    });

    testWidgets('renders custom retry label', (tester) async {
      await tester.pumpWidget(
        wrap(
          MinglitErrorState(
            onRetry: () {},
            retryLabel: '재시도',
          ),
        ),
      );

      expect(find.text('재시도'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    });

    testWidgets('does not render button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitErrorState()),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('icon uses error color from theme', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitErrorState()),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final colorScheme = Theme.of(
        tester.element(find.byType(MinglitErrorState)),
      ).colorScheme;
      expect(icon.color, equals(colorScheme.error));
    });
  });
}
