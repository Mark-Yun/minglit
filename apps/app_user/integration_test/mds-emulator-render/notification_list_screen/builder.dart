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
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 알림 목록 로딩.
  NotificationListScreenBuilder loading() {
    addOverride(
      notificationListProvider.overrideWith(
        LoadingNotificationListNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 알림 목록 오류.
  NotificationListScreenBuilder error() {
    addOverride(
      notificationListProvider.overrideWith(
        ErrorNotificationListNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 알림 2건 표시.
  NotificationListScreenBuilder withNotifications() {
    addOverride(
      notificationListProvider.overrideWith(
        StaticNotificationListNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 읽음 처리된 알림 2건 표시.
  NotificationListScreenBuilder withAllReadNotifications() {
    addOverride(
      notificationListProvider.overrideWith(
        AllReadNotificationListNotifier.new,
      ),
    );
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  /// 다크 모드 토글.
  NotificationListScreenBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }
}
