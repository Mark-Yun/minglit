import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip.dart';

void main() {
  Widget buildApp(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? MinglitTheme.materialTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MinglitChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildApp(const MinglitChip(label: '이벤트')),
      );

      expect(find.text('이벤트'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const MinglitChip(label: '아이콘', icon: Icons.star),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildApp(
          MinglitChip(label: '탭 테스트', onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(MinglitChip));
      expect(tapped, isTrue);
    });

    testWidgets('non-interactive chip has no ConstrainedBox for touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(const MinglitChip(label: '읽기 전용')),
      );

      // static chip should NOT wrap with ConstrainedBox(minHeight:48)
      expect(find.byType(InkWell), findsNothing);
    });

    // Fix #1376: A11Y — 인터랙티브 칩의 최소 터치 영역 48dp 검증
    testWidgets('interactive chip touch target is at least 48dp', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          MinglitChip(label: '인터랙티브', onTap: () {}),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.byType(InkWell),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(
        constrainedBox.constraints.minHeight,
        greaterThanOrEqualTo(48.0),
        reason: 'interactive chip touch target must be at least 48dp tall',
      );
      expect(
        constrainedBox.constraints.minWidth,
        greaterThanOrEqualTo(48.0),
        reason: 'interactive chip touch target must be at least 48dp wide',
      );
    });

    // Dark mode 색상은 colorScheme 기반이므로 이미 적용됨
    testWidgets('uses colorScheme.onSurfaceVariant text in default state', (
      tester,
    ) async {
      final lightTheme = MinglitTheme.materialTheme;
      await tester.pumpWidget(
        buildApp(
          const MinglitChip(label: '텍스트 색상'),
          theme: lightTheme,
        ),
      );

      final textWidget = tester.widget<Text>(find.text('텍스트 색상'));
      expect(
        textWidget.style?.color,
        lightTheme.colorScheme.onSurfaceVariant,
        reason: 'default chip text should use colorScheme.onSurfaceVariant',
      );
    });
  });
}
