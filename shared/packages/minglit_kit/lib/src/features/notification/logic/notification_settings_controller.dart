import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/data/models/user_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_settings_controller.g.dart';

@riverpod
class NotificationSettingsController extends _$NotificationSettingsController {
  @override
  FutureOr<UserSettings?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final repository = ref.watch(notificationRepositoryProvider);
    final settings = await repository.getSettings(user.id);
    
    // If settings don't exist, we might return a default object or null.
    // The backend trigger creates it, so it should exist.
    // If it returns null (e.g. trigger failed or new user before trigger), 
    // we return a default object without ID (or handle gracefully).
    // Let's assume default if null.
    
    return settings ?? UserSettings(
        userId: user.id, 
        updatedAt: DateTime.now(),
        // Defaults: marketing=false, service=true
    );
  }

  Future<void> updateSetting(String key, bool value) async {
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
    } catch (e, st) {
      // 3. Revert on Error
      state = previousState;
      // Or set AsyncError but keep data? 
      // Usually revert is better for toggles.
      // We can also rethrow to let UI handle error message.
      state = AsyncError(e, st); // This will show error state in UI
    }
  }
}
