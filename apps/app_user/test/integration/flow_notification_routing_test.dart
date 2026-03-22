import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/my_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/mock_data.dart';
import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  group('알림 플로우', () {
    testWidgets('홈 → 알림 아이콘 tap → NotificationListScreen', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final mockRepo = MockNotificationRepository();
      when(mockRepo.getNotifications).thenAnswer((_) async => []);
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          additionalOverrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pump();
      await tester.pump();

      expect(find.byType(NotificationListScreen), findsOneWidget);
    });

    testWidgets('빈 알림 → "알림이 없습니다."', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final mockRepo = MockNotificationRepository();
      when(mockRepo.getNotifications).thenAnswer((_) async => []);
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/notifications',
          additionalOverrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('알림이 없습니다.'), findsOneWidget);
    });

    testWidgets('알림 읽음/안읽음 → 배경색 + 폰트 weight 분기', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final mockRepo = MockNotificationRepository();
      final notifications = [
        {
          'id': 'n-read',
          'user_id': 'test-user-id',
          'title': '읽은 알림',
          'body': '읽음 본문',
          'type': 'general',
          'is_read': true,
          'created_at': DateTime.now().toIso8601String(),
          'data': <String, dynamic>{},
        },
        {
          'id': 'n-unread',
          'user_id': 'test-user-id',
          'title': '안읽은 알림',
          'body': '안읽음 본문',
          'type': 'general',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'data': <String, dynamic>{},
        },
      ];
      when(mockRepo.getNotifications).thenAnswer((_) async => notifications);
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/notifications',
          additionalOverrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // 읽은 알림: fontWeight normal, 기본 배경색 (tileColor null)
      final readTitle = tester.widget<Text>(find.text('읽은 알림'));
      expect(readTitle.style?.fontWeight, FontWeight.normal);
      final readTile = tester.widget<ListTile>(
        find.ancestor(of: find.text('읽은 알림'), matching: find.byType(ListTile)),
      );
      expect(readTile.tileColor, isNull);

      // 안읽은 알림: fontWeight bold, primary 계열 배경색 적용
      final unreadTitle = tester.widget<Text>(find.text('안읽은 알림'));
      expect(unreadTitle.style?.fontWeight, FontWeight.bold);
      final unreadTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('안읽은 알림'),
          matching: find.byType(ListTile),
        ),
      );
      expect(unreadTile.tileColor, isNotNull);
    });

    testWidgets('알림 tap → markAsRead + deep_link로 이동', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final mockRepo = MockNotificationRepository();
      final notifications = [
        {
          'id': 'n-1',
          'user_id': 'test-user-id',
          'title': '이벤트 알림',
          'body': '새 이벤트가 있습니다.',
          'type': 'general',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'deep_link': '/events/test-event-0',
          'data': <String, dynamic>{},
        },
      ];
      when(mockRepo.getNotifications).thenAnswer((_) async => notifications);
      when(() => mockRepo.markAsRead('n-1')).thenAnswer((_) async {});
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/notifications',
          additionalOverrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          events: createFakeEvents(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('이벤트 알림'));
      await tester.pump();
      await tester.pump();

      verify(() => mockRepo.markAsRead('n-1')).called(1);
    });

    testWidgets('알림 스와이프 → Dismissible 삭제', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final mockRepo = MockNotificationRepository();
      final notifications = [
        {
          'id': 'n-dismiss',
          'user_id': 'test-user-id',
          'title': '삭제할 알림',
          'body': '스와이프로 삭제',
          'type': 'general',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'data': <String, dynamic>{},
        },
      ];
      when(mockRepo.getNotifications).thenAnswer((_) async => notifications);
      when(
        () => mockRepo.deleteNotification('n-dismiss'),
      ).thenAnswer((_) async {});
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/notifications',
          additionalOverrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // 왼쪽으로 스와이프 (endToStart)
      await tester.drag(find.text('삭제할 알림'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteNotification('n-dismiss')).called(1);
    });

    testWidgets('무효한 deep_link (null) → "이동할 링크가 없습니다" SnackBar', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      final mockRepo = MockNotificationRepository();
      final notifications = [
        {
          'id': 'n-no-link',
          'user_id': 'test-user-id',
          'title': '링크 없는 알림',
          'body': '딥링크가 null',
          'type': 'general',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
          'deep_link': null,
          'data': <String, dynamic>{},
        },
      ];
      when(mockRepo.getNotifications).thenAnswer((_) async => notifications);
      when(() => mockRepo.markAsRead('n-no-link')).thenAnswer((_) async {});
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/notifications',
          additionalOverrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('링크 없는 알림'));
      await tester.pump();

      expect(find.text('이동할 링크가 없습니다.'), findsOneWidget);
    });
  });

  group('보호된 경로 리다이렉트', () {
    testWidgets('비로그인 /my → /login?from=/my', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(createTestApp(initialLocation: '/my'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      // from 파라미터가 /my로 전달되었는지 확인
      final loginPage = tester.widget<LoginPage>(find.byType(LoginPage));
      expect(loginPage.from, '/my');
    });

    testWidgets('비로그인 /events/:id/apply → /login?from=/events/:id/apply', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/events/test-event-id/apply'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      final loginPage = tester.widget<LoginPage>(find.byType(LoginPage));
      expect(loginPage.from, '/events/test-event-id/apply');
    });

    testWidgets('비로그인 /purchase-history → /login?from=/purchase-history', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/purchase-history'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      final loginPage = tester.widget<LoginPage>(find.byType(LoginPage));
      expect(loginPage.from, '/purchase-history');
    });
  });

  group('로그인 복귀', () {
    testWidgets('from 파라미터 → 로그인 후 원래 경로로 복귀', (tester) async {
      setKoreanLocale(tester);
      final user = createMockUserForTest();
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: user,
          initialLocation: '/login?from=%2Fmy',
        ),
      );
      await tester.pump();
      await tester.pump();

      // 로그인 상태 + from=/my → /my로 리다이렉트 (LoginPage 미표시, MyPage 표시)
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(MyPage), findsOneWidget);
    });
  });
}
