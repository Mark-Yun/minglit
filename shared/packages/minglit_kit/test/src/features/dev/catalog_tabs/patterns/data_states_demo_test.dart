// Tests for DataStatesDemoPage — P6 data states pattern demo (#715)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/data_states_demo.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('DemoState enum', () {
    test('has exactly 4 values', () {
      expect(DemoState.values.length, 4);
    });

    test('contains data, loading, error, empty', () {
      expect(DemoState.values, containsAll([
        DemoState.data,
        DemoState.loading,
        DemoState.error,
        DemoState.empty,
      ]));
    });
  });

  group('MinglitIconSize.xlarge', () {
    test('equals 32.0', () {
      expect(MinglitIconSize.xlarge, 32.0);
    });
  });

  group('DataStatesDemoPage — renders without error', () {
    testWidgets('initial state is data — shows list items', (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      // SegmentedButton is present
      expect(find.byType(SegmentedButton<DemoState>), findsOneWidget);

      // Mock data items are visible
      expect(find.text('서울 한강공원 피크닉'), findsOneWidget);
    });

    testWidgets('loading state renders skeleton and spinner', (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      // Tap the "로딩" segment; use pump instead of pumpAndSettle because
      // MinglitSkeleton runs an infinite animation that never settles.
      await tester.tap(find.text('로딩'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MinglitSkeleton), findsWidgets);
    });

    testWidgets('empty state renders icon, title, description and CTA button',
        (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      await tester.tap(find.text('빈 목록'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('등록된 항목이 없습니다'), findsOneWidget);
      expect(find.text('아직 항목이 없어요. 새 항목을 추가해 보세요.'), findsOneWidget);
      expect(find.text('항목 추가'), findsOneWidget);
    });

    testWidgets('empty state icon is 32px (MinglitIconSize.xlarge)',
        (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      await tester.tap(find.text('빈 목록'));
      await tester.pumpAndSettle();

      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.inbox_outlined),
      );
      expect(iconWidget.size, MinglitIconSize.xlarge);
      expect(iconWidget.size, 32.0);
    });

    testWidgets('error state renders icon, title, description and retry button',
        (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      await tester.tap(find.text('오류'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('오류가 발생했습니다'), findsOneWidget);
      expect(find.text('데이터를 불러오지 못했습니다.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('error state icon is 32px (MinglitIconSize.xlarge)',
        (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      await tester.tap(find.text('오류'));
      await tester.pumpAndSettle();

      final iconWidget = tester.widget<Icon>(
        find.byIcon(Icons.error_outline),
      );
      expect(iconWidget.size, MinglitIconSize.xlarge);
      expect(iconWidget.size, 32.0);
    });
  });

  group('DataStatesDemoPage — state transitions', () {
    testWidgets('tapping CTA in empty state returns to data state',
        (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      // Go to empty
      await tester.tap(find.text('빈 목록'));
      await tester.pumpAndSettle();
      expect(find.text('항목 추가'), findsOneWidget);

      // Tap CTA
      await tester.tap(find.text('항목 추가'));
      await tester.pumpAndSettle();

      // Back to data state — list items visible
      expect(find.text('서울 한강공원 피크닉'), findsOneWidget);
    });

    testWidgets('tapping retry in error state returns to data state',
        (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      // Go to error
      await tester.tap(find.text('오류'));
      await tester.pumpAndSettle();
      expect(find.text('다시 시도'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      // Back to data state
      expect(find.text('서울 한강공원 피크닉'), findsOneWidget);
    });

    testWidgets('can cycle through all 4 states without error', (tester) async {
      await tester.pumpWidget(_wrap(const DataStatesDemoPage()));
      await tester.pump();

      // Tap each state; use pump instead of pumpAndSettle because the
      // loading state contains an infinite skeleton animation.
      for (final label in ['로딩', '오류', '빈 목록', '데이터']) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Should be back on data state
      expect(find.text('서울 한강공원 피크닉'), findsOneWidget);
    });
  });
}
