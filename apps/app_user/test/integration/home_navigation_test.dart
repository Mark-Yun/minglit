import 'package:app_user/src/features/home/my_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('Home Navigation Flow', () {
    testWidgets('비로그인 홈: person_outline 아이콘 표시', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    testWidgets('로그인 홈: notifications 아이콘 표시', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(isLoggedIn: true, currentUser: user),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('홈: search 아이콘은 항상 표시', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('로그인 홈: /my 라우트 → MyPage', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/my',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(MyPage), findsOneWidget);
    });
  });
}
