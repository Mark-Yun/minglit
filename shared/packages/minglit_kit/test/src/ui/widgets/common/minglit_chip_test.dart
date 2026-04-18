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

    // Fix #1376: InkWell이 48dp 전체 영역을 hit test 대상으로 가짐을 검증.
    // 시각적 칩보다 작은 위치(하단 투명 영역)를 탭해도 콜백이 실행되어야 함.
    testWidgets('tap on transparent area outside visual chip fires onTap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        buildApp(
          SizedBox(
            width: 200,
            child: Align(
              alignment: Alignment.topLeft,
              child: MinglitChip(
                label: '터치영역',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      // InkWell의 실제 렌더링 크기가 minHeight 48dp 이상인지 확인
      final inkWell = find.byType(InkWell);
      final inkWellSize = tester.getSize(inkWell);
      expect(
        inkWellSize.height,
        greaterThanOrEqualTo(48.0),
        reason: 'InkWell rendered height must be at least 48dp',
      );

      // InkWell 상단 (시각적 칩 위) 투명 영역 탭
      final inkWellRect = tester.getRect(inkWell);
      final tapPoint = Offset(inkWellRect.center.dx, inkWellRect.top + 4);
      await tester.tapAt(tapPoint);
      expect(
        tapped,
        isTrue,
        reason: 'tap on transparent area should fire onTap',
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

    group('Semantics', () {
      testWidgets(
        'interactive chip: SemanticsNode has single label and button flag',
        (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(
            buildApp(MinglitChip(label: '인터랙티브 칩', onTap: () {})),
          );

          expect(
            tester.getSemantics(find.byType(MinglitChip)),
            matchesSemantics(label: '인터랙티브 칩', isButton: true),
            reason:
                'interactive chip must expose a single label without '
                'duplication and declare button role',
          );

          handle.dispose();
        },
      );

      testWidgets(
        'non-interactive chip: SemanticsNode has single label, no button flag',
        (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(
            buildApp(const MinglitChip(label: '읽기 전용 칩')),
          );

          expect(
            tester.getSemantics(find.byType(MinglitChip)),
            matchesSemantics(label: '읽기 전용 칩', isButton: false),
            reason:
                'static chip must expose a single label without duplication '
                'and must not declare button role',
          );

          handle.dispose();
        },
      );
    });
  });
}
