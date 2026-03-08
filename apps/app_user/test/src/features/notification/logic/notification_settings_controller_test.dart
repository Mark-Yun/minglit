import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/user_settings.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/notification/logic/notification_settings_controller.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  late MockNotificationRepository mockRepo;
  late MockUser mockUser;

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user1');
  });

  group('NotificationSettingsController', () {
    test('build returns settings when user is logged in', () async {
      final mockSettings = UserSettings(
        userId: 'user1',
        marketingConsent: true,
        serviceNotification: false,
        updatedAt: DateTime.now(),
      );

      when(
        () => mockRepo.getSettings('user1'),
      ).thenAnswer((_) async => mockSettings);

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        notificationSettingsControllerProvider.future,
      );
      expect(result, mockSettings);
    });

    test('build returns null when user is not logged in', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        notificationSettingsControllerProvider.future,
      );
      expect(result, isNull);
    });

    test('updateSetting calls repository and updates state', () async {
      final initialSettings = UserSettings(
        userId: 'user1',
        updatedAt: DateTime.now(),
      );

      when(
        () => mockRepo.getSettings('user1'),
      ).thenAnswer((_) async => initialSettings);
      when(
        () => mockRepo.updateSettings(any(), any()),
      ).thenAnswer((_) async => {});

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => mockUser),
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initialize
      await container.read(notificationSettingsControllerProvider.future);

      // Update
      await container
          .read(notificationSettingsControllerProvider.notifier)
          .updateSetting(key: 'marketing_consent', value: true);

      // Check State
      final newState = await container.read(
        notificationSettingsControllerProvider.future,
      );
      expect(newState!.marketingConsent, true);

      // Check Repo Call
      verify(
        () => mockRepo.updateSettings('user1', {'marketing_consent': true}),
      ).called(1);
    });
  });
}
