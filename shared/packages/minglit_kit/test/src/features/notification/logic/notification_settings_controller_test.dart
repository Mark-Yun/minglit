import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/user_settings.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/features/notification/logic/notification_settings_controller.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_utils.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockNotificationRepository mockRepo;
  late MockUser mockUser;

  final testSettings = UserSettings(
    userId: 'user_1',
    updatedAt: DateTime(2026, 3, 20),
  );

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

  group('NotificationSettingsController', () {
    test('returns null when user is not logged in', () async {
      final container = createTestContainer();

      final result = await container.read(
        notificationSettingsControllerProvider.future,
      );

      expect(result, isNull);
    });

    test('loads settings from repository', () async {
      when(
        () => mockRepo.getSettings('user_1'),
      ).thenAnswer((_) async => testSettings);

      final container = createTestContainer(user: mockUser);

      final result = await container.read(
        notificationSettingsControllerProvider.future,
      );

      expect(result, equals(testSettings));
    });

    test(
      'returns default settings when repository returns null',
      () async {
        when(
          () => mockRepo.getSettings('user_1'),
        ).thenAnswer((_) async => null);

        final container = createTestContainer(user: mockUser);

        final result = await container.read(
          notificationSettingsControllerProvider.future,
        );

        expect(result, isNotNull);
        expect(result!.userId, 'user_1');
        expect(result.marketingConsent, isFalse);
        expect(result.serviceNotification, isTrue);
      },
    );

    group('updateSetting', () {
      test('updates marketing_consent optimistically', () async {
        when(
          () => mockRepo.getSettings('user_1'),
        ).thenAnswer((_) async => testSettings);
        when(
          () => mockRepo.updateSettings(
            'user_1',
            {'marketing_consent': true},
          ),
        ).thenAnswer((_) async {
          return null;
        });

        final container = createTestContainer(user: mockUser);
        await container.read(
          notificationSettingsControllerProvider.future,
        );

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );

        await notifier.updateSetting(
          key: 'marketing_consent',
          value: true,
        );

        final state = container.read(
          notificationSettingsControllerProvider,
        );
        expect(state.value!.marketingConsent, isTrue);

        verify(
          () => mockRepo.updateSettings(
            'user_1',
            {'marketing_consent': true},
          ),
        ).called(1);
      });

      test('updates service_notification optimistically', () async {
        when(
          () => mockRepo.getSettings('user_1'),
        ).thenAnswer((_) async => testSettings);
        when(
          () => mockRepo.updateSettings(
            'user_1',
            {'service_notification': false},
          ),
        ).thenAnswer((_) async {
          return null;
        });

        final container = createTestContainer(user: mockUser);
        await container.read(
          notificationSettingsControllerProvider.future,
        );

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );

        await notifier.updateSetting(
          key: 'service_notification',
          value: false,
        );

        final state = container.read(
          notificationSettingsControllerProvider,
        );
        expect(state.value!.serviceNotification, isFalse);
      });

      test('reverts on server error', () async {
        when(
          () => mockRepo.getSettings('user_1'),
        ).thenAnswer((_) async => testSettings);
        when(
          () => mockRepo.updateSettings(
            'user_1',
            {'marketing_consent': true},
          ),
        ).thenThrow(Exception('Server error'));

        final container = createTestContainer(user: mockUser);
        await container.read(
          notificationSettingsControllerProvider.future,
        );

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );

        await notifier.updateSetting(
          key: 'marketing_consent',
          value: true,
        );

        final state = container.read(
          notificationSettingsControllerProvider,
        );
        expect(state, isA<AsyncError<UserSettings?>>());
      });

      test('ignores unknown setting keys', () async {
        when(
          () => mockRepo.getSettings('user_1'),
        ).thenAnswer((_) async => testSettings);

        final container = createTestContainer(user: mockUser);
        await container.read(
          notificationSettingsControllerProvider.future,
        );

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );

        await notifier.updateSetting(
          key: 'unknown_key',
          value: true,
        );

        verifyNever(
          () => mockRepo.updateSettings(any(), any()),
        );
      });

      test('does nothing when user is null', () async {
        final container = createTestContainer();
        await container.read(
          notificationSettingsControllerProvider.future,
        );

        final notifier = container.read(
          notificationSettingsControllerProvider.notifier,
        );

        await notifier.updateSetting(
          key: 'marketing_consent',
          value: true,
        );

        verifyNever(
          () => mockRepo.updateSettings(any(), any()),
        );
      });
    });
  });
}
