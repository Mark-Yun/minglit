import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_filter_chip.dart';

void main() {
  Widget buildApp(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? MinglitTheme.materialTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MinglitFilterChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitFilterChip(
            label: '최신순',
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('최신순'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitFilterChip(
            label: '정렬',
            isSelected: false,
            onTap: () {},
            icon: Icons.sort,
          ),
        ),
      );

      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildApp(
          MinglitFilterChip(
            label: '탭 테스트',
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('탭 테스트'));
      expect(tapped, isTrue);
    });

    // Fix #1376: 다크모드 — colorScheme 기반 색상 확인
    testWidgets('selected uses colorScheme.onSurface background in light mode', (
      tester,
    ) async {
      final lightTheme = MinglitTheme.materialTheme;
      await tester.pumpWidget(
        buildApp(
          MinglitFilterChip(
            label: '선택됨',
            isSelected: true,
            onTap: () {},
          ),
          theme: lightTheme,
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MinglitFilterChip),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        lightTheme.colorScheme.onSurface,
        reason: 'selected chip background should use colorScheme.onSurface',
      );
    });

    testWidgets('dark mode selected bg equals colorScheme.onSurface', (
      tester,
    ) async {
      final darkTheme = MinglitTheme.materialThemeDark;
      await tester.pumpWidget(
        buildApp(
          MinglitFilterChip(
            label: '선택됨',
            isSelected: true,
            onTap: () {},
          ),
          theme: darkTheme,
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MinglitFilterChip),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.color,
        darkTheme.colorScheme.onSurface,
        reason: 'dark mode selected bg should use colorScheme.onSurface',
      );
    });

    // Fix #1376: A11Y — 최소 터치 영역 48dp 검증
    testWidgets('touch target is at least 48dp tall', (tester) async {
      await tester.pumpWidget(
        buildApp(
          MinglitFilterChip(
            label: '터치영역',
            isSelected: false,
            onTap: () {},
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(
        constrainedBox.constraints.minHeight,
        greaterThanOrEqualTo(48.0),
        reason: 'touch target must be at least 48dp tall (WCAG)',
      );
      expect(
        constrainedBox.constraints.minWidth,
        greaterThanOrEqualTo(48.0),
        reason: 'touch target must be at least 48dp wide (WCAG)',
      );
    });
  });
}
