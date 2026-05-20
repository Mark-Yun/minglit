// MDS render catalog registry — app_partner.
//
// 등록된 catalog 목록. 알파벳 순서 유지.
// 새 screen 추가 시 아래 import + catalog 변수 참조 추가.

import 'checkin_placeholder_page/checkin_placeholder_page_test.dart'
    as checkin_placeholder_page;
import 'recurrence_management_screen/recurrence_management_screen_test.dart'
    as recurrence_management_screen;

/// 모든 등록된 catalog.
final List<Object> catalogs = [
  checkin_placeholder_page.catalog,
  recurrence_management_screen.catalog,
];
