// NotificationSettingsScreenBuilder — notification_settings_screen 전용 fluent API.

import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/notifiers.dart';

class NotificationSettingsScreenBuilder
    extends MdsScreenBuilder<NotificationSettingsScreen> {
  NotificationSettingsScreenBuilder()
    : super(
        page: const NotificationSettingsScreen(),
        base: [
          notificationSettingsControllerProvider.overrideWith(
            LoadedNotificationSettingsNotifier.new,
          ),
        ],
      );

  /// 다크 모드 토글.
  NotificationSettingsScreenBuilder dark() {
    useDarkTheme();
    return this;
  }
}
