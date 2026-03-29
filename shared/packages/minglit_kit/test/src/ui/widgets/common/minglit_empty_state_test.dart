import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_empty_state.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MinglitEmptyState', () {
    testWidgets('renders with required params only', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState(title: '데이터가 없습니다')),
      );

      expect(find.text('데이터가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byType(MinglitEmptyState), findsOneWidget);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitEmptyState(
            title: '검색 결과 없음',
            icon: Icons.search_off,
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MinglitEmptyState(
            title: '이벤트 없음',
            subtitle: '새 이벤트를 만들어보세요',
          ),
        ),
      );

      expect(find.text('이벤트 없음'), findsOneWidget);
      expect(find.text('새 이벤트를 만들어보세요'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState(title: '빈 상태')),
      );

      // Only title text should exist
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders action button when both label and callback provided', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          MinglitEmptyState(
            title: '항목 없음',
            actionLabel: '새로 만들기',
            onAction: () => tapped = true,
          ),
        ),
      );

      expect(find.text('새로 만들기'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not render button when only actionLabel is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const MinglitEmptyState(
            title: '빈 상태',
            actionLabel: '버튼 라벨',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('does not render button when only onAction is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(MinglitEmptyState(title: '빈 상태', onAction: () {})),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('icon uses outline color from theme', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState(title: '빈 상태')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final colorScheme = Theme.of(
        tester.element(find.byType(MinglitEmptyState)),
      ).colorScheme;
      expect(icon.color, equals(colorScheme.outline));
    });
  });
}
