import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import '../utils/mocks.dart';
import 'utils/mock_data.dart';
import 'utils/test_app.dart';

void main() {
  group('Notification Center CUJ', () {
    testWidgets('알림 빈 상태', (tester) async {
      setKoreanLocale(tester);
      final fakeUser = createFakeUser();
      final mockNotificationRepo = MockNotificationRepository();
      when(() => mockNotificationRepo.getNotifications()).thenAnswer((_) async => []);
      await tester.pumpWidget(ProviderScope(
        overrides: [currentUserProvider.overrideWith((_) => fakeUser), notificationRepositoryProvider.overrideWithValue(mockNotificationRepo)],
        child: const MaterialApp(home: NotificationListScreen()),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('알림이 없습니다.'), findsOneWidget);
    });
  });
}
