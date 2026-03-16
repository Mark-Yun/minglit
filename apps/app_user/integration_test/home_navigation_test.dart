import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:app_user/src/features/search/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Navigation Flow', () {
    // Test 1: Unauthenticated home — correct UI
    testWidgets('비로그인 홈: person_outline 아이콘 표시, notifications 미표시', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    // Test 2: Authenticated home — correct UI
    testWidgets('로그인 홈: notifications 아이콘 표시, person_outline 미표시', (
      tester,
    ) async {
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

    // Test 3: Tap search icon → SearchPage
    testWidgets('홈: search 아이콘 탭 → SearchPage로 이동', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SearchPage), findsOneWidget);
    });

    // Test 4: Tap person_outline (unauthenticated) → LoginPage
    testWidgets('비로그인 홈: person_outline 탭 → LoginPage로 이동', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    // Test 5: Tap avatar (authenticated) → MyPage
    testWidgets('로그인 홈: avatar 탭 → MyPage로 이동', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(isLoggedIn: true, currentUser: user),
      );
      await tester.pump();
      await tester.pump();

      // Avatar is a GestureDetector wrapping a CircleAvatar
      await tester.tap(find.byType(CircleAvatar).first);
      await tester.pump();
      await tester.pump();

      expect(find.byType(MyPage), findsOneWidget);
    });

    // Test 6: Empty events — empty state text
    testWidgets('홈: 이벤트 없을 때 empty state 텍스트 표시', (tester) async {
      setKoreanLocale(tester);
      // Default createTestApp overrides recommendationEventsProvider
      // with empty list
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();
      await tester.pump(); // extra pump for async provider

      expect(find.text('추천 이벤트가 없습니다'), findsOneWidget);
    });

    // Test 7: Events list — events rendered
    testWidgets('홈: 이벤트 있을 때 MinglitEventCard 렌더링', (tester) async {
      setKoreanLocale(tester);
      final events = createMockEventsForTest();
      await tester.pumpWidget(
        createTestApp(
          additionalOverrides: [
            recommendationEventsProvider.overrideWith((_) async => events),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(MinglitEventCard), findsWidgets);
    });

    // Test 8: Search icon always visible
    testWidgets('홈: search 아이콘은 항상 표시', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    // Test 9: Home → EventDetail navigation via direct route
    testWidgets('홈: 이벤트 카드 탭 → EventDetailPage로 이동', (tester) async {
      setKoreanLocale(tester);
      final events = createMockEventsForTest();
      final mockEventRepo = MockEventRepository();
      // Stub required repo calls for EventDetailPage
      when(() => mockEventRepo.getEventById(any())).thenAnswer(
        (_) async => events.first,
      );
      when(
        () => mockEventRepo.getEntryGroupParticipantCounts(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockEventRepo.getEventsByType(
          type: any(named: 'type'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => events);

      await tester.pumpWidget(
        createTestApp(
          additionalOverrides: [
            eventRepositoryProvider.overrideWithValue(mockEventRepo),
            recommendationEventsProvider.overrideWith((_) async => events),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Tap the first event card
      await tester.tap(find.byType(MinglitEventCard).first);
      await tester.pump();
      await tester.pump();

      expect(find.byType(EventDetailPage), findsOneWidget);
    });
  });
}
