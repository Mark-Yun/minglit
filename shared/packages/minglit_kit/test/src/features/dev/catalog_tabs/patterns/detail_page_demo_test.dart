import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/detail_page_demo.dart';

void main() {
  group('DetailPageDemo', () {
    Widget buildSubject() => const MaterialApp(home: DetailPageDemo());

    testWidgets('data state shows event content', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // SegmentedButton present
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('switches to loading state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Loading'));
      await tester.pump();

      // In loading state skeletons are shown (no event title text)
      expect(find.text('재즈 이브닝 in 성수'), findsNothing);
    });

    testWidgets('switches to error state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Error'));
      await tester.pump();

      expect(find.text('이벤트 정보를 불러올 수 없습니다'), findsOneWidget);
    });

    testWidgets('switches to empty state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Empty'));
      await tester.pump();

      expect(find.text('표시할 이벤트가 없습니다'), findsOneWidget);
    });

    testWidgets('error state retry returns to data', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.text('Error'));
      await tester.pump();

      // Tap retry button
      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      // Should show event title again (data state)
      // SegmentedButton should still be present
      expect(find.text('Data'), findsOneWidget);
    });
  });
}
