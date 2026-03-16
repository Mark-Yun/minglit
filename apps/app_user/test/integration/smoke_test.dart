import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('Smoke Tests — TestApp 인프라 검증', () {
    testWidgets('비로그인 상태: HomePage 렌더링 확인', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('로그인 상태: HomePage 렌더링 확인', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(isLoggedIn: true, currentUser: user),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });
  });
}
