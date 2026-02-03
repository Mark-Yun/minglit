import 'package:app_user/src/features/explore/explore_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget createTestWidget() {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: const ExplorePage(),
    );
  }

  group('ExplorePage', () {
    testWidgets('renders 탐색 app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('탐색'), findsOneWidget);
    });

    testWidgets('renders all 4 event feed type categories', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('내 주변 파티'), findsOneWidget);
      expect(find.text('신규 오픈'), findsOneWidget);
      expect(find.text('마감 임박'), findsOneWidget);
      expect(find.text('얼리버드 특가'), findsOneWidget);
    });

    testWidgets('renders sort labels as subtitles', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('거리순'), findsOneWidget);
      expect(find.text('최신순'), findsOneWidget);
      expect(find.text('마감순'), findsOneWidget);
      expect(find.text('가격순'), findsOneWidget);
    });

    testWidgets('renders category icons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.fiber_new), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.local_offer), findsOneWidget);
    });

    testWidgets('renders chevron icons for navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    });

    testWidgets('renders 4 Card widgets', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Card), findsNWidgets(4));
    });
  });
}
