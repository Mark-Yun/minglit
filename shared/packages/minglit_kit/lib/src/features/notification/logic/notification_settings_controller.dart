import 'package:minglit_kit/src/data/models/user_settings.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_settings_controller.g.dart';

/// Manages notification settings for the current user.
@riverpod
class NotificationSettingsController extends _$NotificationSettingsController {
  /// Loads the current user's notification settings.
  @override
  FutureOr<UserSettings?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final repository = ref.watch(notificationRepositoryProvider);
    final settings = await repository.getSettings(user.id);

    return settings ??
        UserSettings(
          userId: user.id,
          updatedAt: DateTime.now(),
        );
  }

  /// Updates the setting [key] with the provided [value].
  Future<void> updateSetting({required String key, required bool value}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final previousState = state;
    if (previousState.value == null) return;

    // 1. Optimistic Update
    final currentSettings = previousState.value!;
    UserSettings newSettings;

    if (key == 'marketing_consent') {
      newSettings = currentSettings.copyWith(marketingConsent: value);
    } else if (key == 'service_notification') {
      newSettings = currentSettings.copyWith(serviceNotification: value);
    } else {
      return;
    }

    state = AsyncData(newSettings);

    try {
      // 2. Server Update
      final repository = ref.read(notificationRepositoryProvider);
      await repository.updateSettings(user.id, {key: value});
    } on Object catch (e, st) {
      // 3. Revert on Error
      state = previousState;
      state = AsyncError(e, st); // This will show error state in UI
    }
  }
}
