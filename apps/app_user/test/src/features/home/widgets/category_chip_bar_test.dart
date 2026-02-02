import 'package:app_user/src/features/home/widgets/category_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget createTestWidget() {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: const Scaffold(body: CategoryChipBar()),
    );
  }

  group('CategoryChipBar', () {
    testWidgets('renders all 4 category labels', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('내 주변'), findsOneWidget);
      expect(find.text('신규 오픈'), findsOneWidget);
      expect(find.text('마감 임박'), findsOneWidget);
      expect(find.text('얼리버드'), findsOneWidget);
    });

    testWidgets('renders category icons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.fiber_new), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.local_offer), findsOneWidget);
    });

    testWidgets('renders circle avatars with primary color tint', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      final avatars = tester.widgetList<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatars.length, 4);

      for (final avatar in avatars) {
        expect(avatar.radius, MinglitSpacing.large);
      }
    });
  });
}
