// Catalog registry — 모든 화면 catalog 의 명시적 import.
//
// 새 화면을 추가하면 본 파일에 import + allCatalogs list 에 등록한다.
// (filesystem 자동 스캔 대신 explicit list 사용 — coverage script /
// CI shard 가 빌드 없이 list 를 읽을 수 있도록.)

import '_engine/builder.dart';
import '_engine/catalog.dart';
import 'event_now_bar/event_now_bar_test.dart' as event_now_bar;
import 'event_ongoing_banner/event_ongoing_banner_test.dart'
    as event_ongoing_banner;
import 'home_page/home_page_test.dart' as home_page;
import 'login_page/login_page_test.dart' as login_page;
import 'notification_list_screen/notification_list_screen_test.dart'
    as notification_list_screen;
import 'notification_settings_screen/notification_settings_screen_test.dart'
    as notification_settings_screen;
import 'search_page/search_page_test.dart' as search_page;

/// 모든 cataloged 화면의 명시적 list. 새 화면 추가 시 본 list 에 추가.
final List<MdsCatalog<MdsScreenBuilder<dynamic>>> allCatalogs = [
  event_now_bar.catalog,
  event_ongoing_banner.catalog,
  home_page.catalog,
  login_page.catalog,
  notification_list_screen.catalog,
  notification_settings_screen.catalog,
  search_page.catalog,
];
