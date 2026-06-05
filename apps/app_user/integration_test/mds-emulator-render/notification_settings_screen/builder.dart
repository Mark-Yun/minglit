// NotificationSettingsScreenBuilder
// notification_settings_screen 전용 fluent API.

import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/notifiers.dart';

class NotificationSettingsScreenBuilder
    extends MdsScreenBuilder<NotificationSettingsScreen> {
  NotificationSettingsScreenBuilder()
    : super(
        page: const NotificationSettingsScreen(),
      );

  /// 서비스 ON / 마케팅 OFF (MDS state_1).
  NotificationSettingsScreenBuilder mixed() {
    addOverride(
      notificationSettingsControllerProvider.overrideWith(
        LoadedNotificationSettingsNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 서비스 OFF / 마케팅 OFF (MDS state_2).
  NotificationSettingsScreenBuilder allOff() {
    addOverride(
      notificationSettingsControllerProvider.overrideWith(
        AllOffNotificationSettingsNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 서비스 ON / 마케팅 ON (MDS state_3).
  NotificationSettingsScreenBuilder allOn() {
    addOverride(
      notificationSettingsControllerProvider.overrideWith(
        AllOnNotificationSettingsNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 설정 정보를 가져오는 중 (MDS state_4).
  NotificationSettingsScreenBuilder loading() {
    addOverride(
      notificationSettingsControllerProvider.overrideWith(
        LoadingNotificationSettingsNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 설정 정보 로드/저장 오류 (MDS state_5).
  NotificationSettingsScreenBuilder error() {
    addOverride(
      notificationSettingsControllerProvider.overrideWith(
        ErrorNotificationSettingsNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 다크 모드 토글.
  NotificationSettingsScreenBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }
}
