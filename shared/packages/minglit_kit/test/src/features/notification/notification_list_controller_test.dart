import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_list_controller.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/test_utils.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockNotificationRepository mockRepo;
  late MockUser mockUser;

  final testNotifications = <Map<String, dynamic>>[
    {'id': 'n1', 'title': 'Welcome', 'is_read': false},
    {'id': 'n2', 'title': 'New event', 'is_read': false},
  ];

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_1');
  });

  ProviderContainer createTestContainer({User? user}) {
    return createContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(mockRepo),
        currentUserProvider.overrideWithValue(user),
      ],
    );
  }

  group('NotificationListController', () {
    test('build loads notifications from repository', () async {
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => testNotifications);

      final container = createTestContainer(user: mockUser);

      final result = await container.read(notificationListProvider.future);

      expect(result, equals(testNotifications));
    });

    test('refresh reloads notifications', () async {
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => testNotifications);

      final container = createTestContainer(user: mockUser);
      await container.read(notificationListProvider.future);

      final updatedNotifications = <Map<String, dynamic>>[
        {'id': 'n1', 'title': 'Welcome', 'is_read': true},
      ];
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => updatedNotifications);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.refresh();

      final state = container.read(notificationListProvider);
      expect(state.value, equals(updatedNotifications));
    });

    test('markAsRead updates notification optimistically', () async {
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => testNotifications);
      when(
        () => mockRepo.markAsRead('n1'),
      ).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);
      await container.read(notificationListProvider.future);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.markAsRead('n1');

      final state = container.read(notificationListProvider);
      final updated = state.value!.firstWhere(
        (n) => n['id'] == 'n1',
      );
      expect(updated['is_read'], isTrue);

      verify(() => mockRepo.markAsRead('n1')).called(1);
    });

    test('markAllAsRead calls repository and refreshes', () async {
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => testNotifications);
      when(
        () => mockRepo.markAllAsRead('user_1'),
      ).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);
      await container.read(notificationListProvider.future);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.markAllAsRead();

      verify(() => mockRepo.markAllAsRead('user_1')).called(1);
    });

    test('markAllAsRead does nothing when user is null', () async {
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => testNotifications);

      final container = createTestContainer();
      await container.read(notificationListProvider.future);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.markAllAsRead();

      verifyNever(() => mockRepo.markAllAsRead(any()));
    });

    test('deleteNotification removes item optimistically', () async {
      when(
        () => mockRepo.getNotifications(),
      ).thenAnswer((_) async => testNotifications);
      when(
        () => mockRepo.deleteNotification('n1'),
      ).thenAnswer((_) async {});

      final container = createTestContainer(user: mockUser);
      await container.read(notificationListProvider.future);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.deleteNotification('n1');

      final state = container.read(notificationListProvider);
      expect(state.value!.length, 1);
      expect(state.value!.first['id'], 'n2');

      verify(() => mockRepo.deleteNotification('n1')).called(1);
    });
  });
}
