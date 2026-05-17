// NotificationListScreenBuilder — notification_list_screen 전용 fluent API.

import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/notifiers.dart';

class NotificationListScreenBuilder
    extends MdsScreenBuilder<NotificationListScreen> {
  NotificationListScreenBuilder()
    : super(
        page: const NotificationListScreen(),
        base: [],
      );

  /// 알림 없음 (빈 상태).
  NotificationListScreenBuilder withEmpty() {
    addOverride(
      notificationListProvider.overrideWith(
        EmptyNotificationListNotifier.new,
      ),
    );
    return this;
  }

  /// 알림 2건 표시.
  NotificationListScreenBuilder withNotifications() {
    addOverride(
      notificationListProvider.overrideWith(
        StaticNotificationListNotifier.new,
      ),
    );
    return this;
  }

  /// 다크 모드 토글.
  NotificationListScreenBuilder dark() {
    useDarkTheme();
    return this;
  }
}
