import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/async_wrapper_demo.dart';

void main() {
  Widget buildApp() {
    return const MaterialApp(
      home: AsyncWrapperDemoPage(),
    );
  }

  group('AsyncWrapperDemoPage', () {
    testWidgets('renders without error in default data state', (tester) async {
      await tester.pumpWidget(buildApp());
      // Allow skeleton animation frames to settle
      await tester.pump();

      expect(find.byType(AsyncWrapperDemoPage), findsOneWidget);
      expect(find.byType(SegmentedButton<AsyncDemoState>), findsOneWidget);
    });

    testWidgets('shows data list items when data state is selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Default state is data — mock items should be visible
      expect(find.text('첫 번째 항목'), findsOneWidget);
      expect(find.text('두 번째 항목'), findsOneWidget);
      expect(find.text('세 번째 항목'), findsOneWidget);
    });

    testWidgets('shows skeleton when loading state is selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Tap the loading segment
      await tester.tap(find.text('loading'));
      await tester.pump();

      // Skeleton rows should appear — mock items should NOT be visible
      expect(find.text('첫 번째 항목'), findsNothing);
    });

    testWidgets('shows error widget when error state is selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Tap the error segment
      await tester.tap(find.text('error'));
      await tester.pump();

      expect(find.text('오류가 발생했습니다.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('can transition between all three states', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // data → loading
      await tester.tap(find.text('loading'));
      await tester.pump();
      expect(find.text('첫 번째 항목'), findsNothing);

      // loading → error
      await tester.tap(find.text('error'));
      await tester.pump();
      expect(find.text('오류가 발생했습니다.'), findsOneWidget);

      // error → data
      await tester.tap(find.text('data'));
      await tester.pump();
      expect(find.text('첫 번째 항목'), findsOneWidget);
    });

    testWidgets("shows Do / Don't sections", (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(
        find.text('Do — MinglitAsyncValueWidget 사용'),
        findsOneWidget,
      );
      expect(
        find.textContaining("Don't"),
        findsOneWidget,
      );
    });

    testWidgets('retry button in error view is tappable without crash', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.tap(find.text('error'));
      await tester.pump();

      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      // No exception should be thrown
    });
  });
}
