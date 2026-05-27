// Catalog registry — 모든 화면 catalog 의 명시적 import.
//
// 새 화면을 추가하면 본 파일에 import + allCatalogs list 에 등록한다.
// (filesystem 자동 스캔 대신 explicit list 사용 — coverage script /
// CI shard 가 빌드 없이 list 를 읽을 수 있도록.)

import '_engine/builder.dart';
import '_engine/catalog.dart';
import 'account_management_page/account_management_page_test.dart'
    as account_management_page;
import 'auth_callback_page/auth_callback_page_test.dart' as auth_callback_page;
import 'blocked_partners_page/blocked_partners_page_test.dart'
    as blocked_partners_page;
import 'deletion_complete_page/deletion_complete_page_test.dart'
    as deletion_complete_page;
import 'deletion_info_page/deletion_info_page_test.dart' as deletion_info_page;
import 'deletion_reason_page/deletion_reason_page_test.dart'
    as deletion_reason_page;
import 'deletion_verify_page/deletion_verify_page_test.dart'
    as deletion_verify_page;
import 'event_bottom_ticket_bar/event_bottom_ticket_bar_test.dart'
    as event_bottom_ticket_bar;
import 'event_now_bar/event_now_bar_test.dart' as event_now_bar;
import 'event_ongoing_banner/event_ongoing_banner_test.dart'
    as event_ongoing_banner;
import 'home_page/home_page_test.dart' as home_page;
import 'login_page/login_page_test.dart' as login_page;
import 'my_page/my_page_test.dart' as my_page;
import 'my_tickets_page/my_tickets_page_test.dart' as my_tickets_page;
import 'notification_list_screen/notification_list_screen_test.dart'
    as notification_list_screen;
import 'notification_settings_screen/notification_settings_screen_test.dart'
    as notification_settings_screen;
import 'privacy_page/privacy_page_test.dart' as privacy_page;
import 'search_page/search_page_test.dart' as search_page;
import 'signup_consent_page/signup_consent_page_test.dart'
    as signup_consent_page;
import 'tag_event_list_page/tag_event_list_page_test.dart'
    as tag_event_list_page;
import 'ticket_qr_screen/ticket_qr_screen_test.dart' as ticket_qr_screen;

/// 모든 cataloged 화면의 명시적 list. 새 화면 추가 시 본 list 에 추가.
final List<MdsCatalog<MdsScreenBuilder<dynamic>>> allCatalogs = [
  account_management_page.catalog,
  auth_callback_page.catalog,
  blocked_partners_page.catalog,
  deletion_complete_page.catalog,
  deletion_info_page.catalog,
  deletion_info_page.catalogWithReason,
  deletion_reason_page.catalog,
  deletion_verify_page.catalog,
  event_bottom_ticket_bar.catalog,
  event_now_bar.catalog,
  event_ongoing_banner.catalog,
  home_page.catalog,
  login_page.catalog,
  my_tickets_page.catalog,
  my_page.catalog,
  notification_list_screen.catalog,
  notification_settings_screen.catalog,
  privacy_page.catalog,
  search_page.catalog,
  signup_consent_page.catalog,
  tag_event_list_page.catalog,
  ticket_qr_screen.catalog,
];
