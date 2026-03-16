import 'package:app_user/src/features/search/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search Flow', () {
    // Test 1: Search page renders with hint text
    testWidgets('검색 페이지: 기본 상태에서 검색 필드 표시', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/search'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    // Test 2: Search hint text visible
    testWidgets('검색 페이지: 검색 힌트 텍스트 표시', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/search'));
      await tester.pump();
      await tester.pump();

      expect(find.text('이벤트 검색'), findsOneWidget);
    });
  });
}
