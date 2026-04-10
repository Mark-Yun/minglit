import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
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

  group('MinglitEmptyState - fullPage variant', () {
    testWidgets('default variant is fullPage', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState(title: '빈 상태')),
      );

      final widget = tester.widget<MinglitEmptyState>(
        find.byType(MinglitEmptyState),
      );
      expect(widget.variant, equals(MinglitEmptyStateVariant.fullPage));
    });

    testWidgets('fullPage renders 48px icon (display size)', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState(title: '빈 상태')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(MinglitIconSize.display));
    });

    testWidgets(
      'fullPage renders on transparent background (no Container decoration)',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(const MinglitEmptyState(title: '빈 상태')),
        );

        // fullPage는 Container로 감싸지 않으므로 decoration이 있는 Container가 없어야 한다
        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(MinglitEmptyState),
            matching: find.byType(Container),
          ),
        );
        final decorated = containers.where((c) => c.decoration != null);
        expect(decorated, isEmpty);
      },
    );

    testWidgets(
      'fullPage shows CTA when both actionLabel and onAction are provided',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(
            MinglitEmptyState(
              title: '항목 없음',
              actionLabel: '새로 만들기',
              onAction: () {},
            ),
          ),
        );

        expect(find.byType(FilledButton), findsOneWidget);
      },
    );
  });

  group('MinglitEmptyState - card variant', () {
    testWidgets('card variant renders 32px icon (xlarge size)', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.card(title: '카드 빈 상태')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, equals(MinglitIconSize.xlarge));
    });

    testWidgets('card variant icon uses outlineVariant color', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.card(title: '카드 빈 상태')),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final colorScheme = Theme.of(
        tester.element(find.byType(MinglitEmptyState)),
      ).colorScheme;
      expect(icon.color, equals(colorScheme.outlineVariant));
    });

    testWidgets('card variant has background color and borderRadius', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.card(title: '카드 빈 상태')),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MinglitEmptyState),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is BoxDecoration,
          ),
        ),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(
        decoration!.borderRadius,
        equals(BorderRadius.circular(MinglitRadius.card)),
      );

      final colorScheme = Theme.of(
        tester.element(find.byType(MinglitEmptyState)),
      ).colorScheme;
      expect(decoration.color, equals(colorScheme.surfaceContainerLowest));
    });

    testWidgets('card variant does not show CTA button', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.card(title: '카드 빈 상태')),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('card named constructor sets card variant', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.card(title: '카드 빈 상태')),
      );

      final widget = tester.widget<MinglitEmptyState>(
        find.byType(MinglitEmptyState),
      );
      expect(widget.variant, equals(MinglitEmptyStateVariant.card));
    });
  });

  group('MinglitEmptyState - inline variant', () {
    testWidgets('inline variant does not show icon', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.inline(title: '인라인 빈 상태')),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('inline variant does not show CTA button', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.inline(title: '인라인 빈 상태')),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets(
      'inline variant has background color, border, and borderRadius',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(const MinglitEmptyState.inline(title: '인라인 빈 상태')),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MinglitEmptyState),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          ),
        );
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration, isNotNull);
        expect(decoration!.border, isNotNull);
        expect(
          decoration.borderRadius,
          equals(BorderRadius.circular(MinglitRadius.card)),
        );
      },
    );

    testWidgets('inline named constructor sets inline variant', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.inline(title: '인라인 빈 상태')),
      );

      final widget = tester.widget<MinglitEmptyState>(
        find.byType(MinglitEmptyState),
      );
      expect(widget.variant, equals(MinglitEmptyStateVariant.inline));
    });

    testWidgets('inline variant renders title text', (tester) async {
      await tester.pumpWidget(
        wrap(const MinglitEmptyState.inline(title: '인라인 빈 상태')),
      );

      expect(find.text('인라인 빈 상태'), findsOneWidget);
    });
  });

  group('MinglitEmptyState - constructor assertions', () {
    test('assert fails when card variant has actionLabel', () {
      expect(
        () => MinglitEmptyState(
          title: '테스트',
          variant: MinglitEmptyStateVariant.card,
          actionLabel: '액션',
        ),
        throwsAssertionError,
      );
    });

    test('assert fails when inline variant has onAction', () {
      expect(
        () => MinglitEmptyState(
          title: '테스트',
          variant: MinglitEmptyStateVariant.inline,
          onAction: () {},
        ),
        throwsAssertionError,
      );
    });

    test(
      'assert passes when fullPage variant has actionLabel and onAction',
      () {
        expect(
          () => MinglitEmptyState(
            title: '테스트',
            actionLabel: '액션',
            onAction: () {},
          ),
          returnsNormally,
        );
      },
    );
  });
}
